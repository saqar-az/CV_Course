import cv2
import torch
import torch.nn as nn
import torch.nn.functional as F
import numpy as np
from collections import deque
from torchvision.models.video import r3d_18, R3D_18_Weights

WINDOW_SIZE = 16
STRIDE = 4
THRESHOLD_ALERT = 0.70
THRESHOLD_PREALERT = 0.50
SMOOTH_N = 3
EMA_ALPHA = 0.4
FRAME_SIZE_MODEL = (112, 112)
DISPLAY_SIZE = (640, 480)
WRITE_OUTPUT = True
OUTPUT_PATH = "output.mp4"
USE_GRADCAM = True

def disable_inplace_relu(model: nn.Module):
    for m in model.modules():
        if isinstance(m, nn.ReLU):
            m.inplace = False

def load_model(checkpoint="best_model.pth", device=None):
    weights = R3D_18_Weights.KINETICS400_V1
    model = r3d_18(weights=weights)
    model.fc = nn.Linear(model.fc.in_features, 2)
    disable_inplace_relu(model)
    if device is None:
        device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    state = torch.load(checkpoint, map_location=device)
    model.load_state_dict(state)
    model = model.to(device)
    model.eval()
    return model, device

class GradCAM:
    def __init__(self, model, target_layer: nn.Module):
        self.model = model
        self.target_layer = target_layer
        self.activations = None
        self._register_hooks()

    def _register_hooks(self):
        def forward_hook(module, input, output):
            self.activations = output
        self.target_layer.register_forward_hook(forward_hook)

    def generate_cam(self, input_tensor, class_idx, out_size):
        with torch.enable_grad():
            output = self.model(input_tensor)
            loss = output[0, class_idx]
            grads = torch.autograd.grad(
                outputs=loss,
                inputs=self.activations,
                retain_graph=False,
                create_graph=False,
                allow_unused=False
            )[0]
            weights = grads.mean(dim=[2, 3, 4], keepdim=True)
            cam = (weights * self.activations).sum(dim=1).squeeze(0)
            cam = F.relu(cam)
            cam_2d = cam.mean(dim=0).detach().cpu().numpy()
            cam_2d = cv2.resize(cam_2d, out_size)
            cam_2d = (cam_2d - cam_2d.min()) / (cam_2d.max() - cam_2d.min() + 1e-8)
            return cam_2d

def frames_to_tensor(frames_rgb, device):
    arr = np.array(frames_rgb, dtype=np.float32) / 255.0
    tensor = torch.from_numpy(arr).permute(3, 0, 1, 2).unsqueeze(0).to(device)
    return tensor

def overlay_heatmap(frame_bgr, cam_2d):
    cam_uint8 = np.uint8(cam_2d * 255)
    heatmap = cv2.applyColorMap(cam_uint8, cv2.COLORMAP_JET)
    overlay = cv2.addWeighted(frame_bgr, 0.6, heatmap, 0.4, 0)
    return overlay

def run_stream(source=0, checkpoint="best_model.pth"):
    model, device = load_model(checkpoint)

    gradcam = None
    if USE_GRADCAM:
        target_layer = model.layer4[-1].conv2
        gradcam = GradCAM(model, target_layer)

    cap = cv2.VideoCapture(source)
    if not cap.isOpened():
        print(f"Failed to open source: {source}")
        return

    writer = None
    if WRITE_OUTPUT:
        fourcc = cv2.VideoWriter_fourcc(*"mp4v")
        fps = cap.get(cv2.CAP_PROP_FPS)
        if fps <= 0 or np.isnan(fps):
            fps = 25.0
        writer = cv2.VideoWriter(OUTPUT_PATH, fourcc, fps, DISPLAY_SIZE)

    frame_buffer_model = deque(maxlen=WINDOW_SIZE)

    print("Press 'q' to quit.")
    while True:
        ret, frame_bgr = cap.read()
        if not ret:
            break

        display_frame = cv2.resize(frame_bgr, DISPLAY_SIZE)
        model_frame_bgr = cv2.resize(frame_bgr, FRAME_SIZE_MODEL)
        model_frame_rgb = cv2.cvtColor(model_frame_bgr, cv2.COLOR_BGR2RGB)
        frame_buffer_model.append(model_frame_rgb)

        if len(frame_buffer_model) == WINDOW_SIZE:
            frames_rgb = list(frame_buffer_model)
            tensor = frames_to_tensor(frames_rgb, device)

            annotated = display_frame.copy()
            if USE_GRADCAM:
                cam_2d = gradcam.generate_cam(tensor, class_idx=1, out_size=DISPLAY_SIZE)
                annotated = overlay_heatmap(annotated, cam_2d)

            cv2.imshow("Heatmap", annotated)
            if writer is not None:
                writer.write(annotated)

        key = cv2.waitKey(1) & 0xFF
        if key == ord('q'):
            break

    cap.release()
    if writer is not None:
        writer.release()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    run_stream(source="dataset/test/violent/V_372.mp4", checkpoint="best_model.pth")