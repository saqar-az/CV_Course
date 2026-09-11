import os
import cv2
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import Dataset, DataLoader
from torchvision.models.video import r3d_18, R3D_18_Weights
from torch.optim.lr_scheduler import ReduceLROnPlateau
from sklearn.metrics import classification_report, confusion_matrix

def extract_frames(path, resize=(112, 112)):
    cap = cv2.VideoCapture(path)
    frames = []
    while True:
        ret, frame = cap.read()
        if not ret:
            break
        frame = cv2.resize(frame, resize)
        frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        frame = torch.tensor(frame, dtype=torch.float32).permute(2, 0, 1) / 255.0
        frames.append(frame)
    cap.release()
    return frames

def load_video(path, num_frames=16):
    frames = extract_frames(path)
    if len(frames) < num_frames:
        while len(frames) < num_frames:
            frames.append(frames[-1])
    else:
        frames = frames[:num_frames]
    return torch.stack(frames, dim=1)

class ViolenceDataset(Dataset):
    def __init__(self, folder_path, num_frames=16):
        self.samples = []
        self.num_frames = num_frames
        for label, subfolder in enumerate(["non-violent", "violent"]):
            full_path = os.path.join(folder_path, subfolder)
            for file in os.listdir(full_path):
                if file.endswith((".mp4")):
                    self.samples.append((os.path.join(full_path, file), label))

    def __len__(self):
        return len(self.samples)

    def __getitem__(self, idx):
        video_path, label = self.samples[idx]
        video_tensor = load_video(video_path, num_frames=self.num_frames)
        return video_tensor, torch.tensor(label, dtype=torch.long)
    
weights = R3D_18_Weights.KINETICS400_V1
model = r3d_18(weights=weights)
model.fc = nn.Linear(model.fc.in_features, 2)  

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model = model.to(device)

optimizer = optim.Adam(model.parameters(), lr=1e-4)
criterion = nn.CrossEntropyLoss()
scheduler = ReduceLROnPlateau(optimizer, mode="max", factor=0.5, patience=2)

train_dataset = ViolenceDataset("dataset/train")
val_dataset   = ViolenceDataset("dataset/val")
test_dataset  = ViolenceDataset("dataset/test")

train_loader = DataLoader(train_dataset, batch_size=4, shuffle=True)
val_loader   = DataLoader(val_dataset, batch_size=4)
test_loader  = DataLoader(test_dataset, batch_size=4)

class EarlyStopping:
    def __init__(self, patience=5, min_delta=0.0):
        self.patience = patience
        self.min_delta = min_delta
        self.best_acc = 0.0
        self.counter = 0
        self.early_stop = False

    def step(self, val_acc):
        if val_acc > self.best_acc + self.min_delta:
            self.best_acc = val_acc
            self.counter = 0
        else:
            self.counter += 1
            if self.counter >= self.patience:
                self.early_stop = True
        return self.early_stop
    
def train_model(num_epochs=50, resume=False, checkpoint_path=None):
    start_epoch = 0
    best_acc = 0.0
    early_stopping = EarlyStopping(patience=5, min_delta=1e-3)

    if resume and checkpoint_path and os.path.exists(checkpoint_path):
        checkpoint = torch.load(checkpoint_path)
        model.load_state_dict(checkpoint['model_state_dict'])
        optimizer.load_state_dict(checkpoint['optimizer_state_dict'])
        scheduler.load_state_dict(checkpoint['scheduler_state_dict'])
        start_epoch = checkpoint['epoch'] + 1
        best_acc = checkpoint.get('best_acc', 0.0)
        print(f"Resumed from epoch {start_epoch} with best_acc={best_acc:.4f}")

    for epoch in range(start_epoch, num_epochs):
        model.train()
        total_loss = 0
        for inputs, labels in train_loader:
            inputs, labels = inputs.to(device), labels.to(device)
            optimizer.zero_grad()
            outputs = model(inputs)
            loss = criterion(outputs, labels)
            loss.backward()
            optimizer.step()
            total_loss += loss.item()

        model.eval()
        correct, total = 0, 0
        with torch.no_grad():
            for inputs, labels in val_loader:
                inputs, labels = inputs.to(device), labels.to(device)
                outputs = model(inputs)
                _, preds = torch.max(outputs, 1)
                correct += (preds == labels).sum().item()
                total += labels.size(0)

        val_acc = correct / total
        scheduler.step(val_acc)

        print(f"Epoch {epoch+1}/{num_epochs}, Loss: {total_loss:.4f}, Val Acc: {val_acc:.4f}")
        torch.save({
            'epoch': epoch,
            'model_state_dict': model.state_dict(),
            'optimizer_state_dict': optimizer.state_dict(),
            'scheduler_state_dict': scheduler.state_dict(),
            'loss': total_loss,
            'best_acc': best_acc
        }, f"checkpoint_epoch_{epoch+1}.pth")

        if val_acc > best_acc:
            best_acc = val_acc
            torch.save(model.state_dict(), "best_model.pth")
            print(f"Saved new best model at epoch {epoch+1} with Val Acc {val_acc:.4f}")

        if early_stopping.step(val_acc):
            print(f"Early stopping triggered at epoch {epoch+1}")
            break

    torch.save(model.state_dict(), "final_model.pth")
    print("Final model saved as final_model.pth")

train_model(num_epochs=50)

y_true, y_pred = [], []
model.load_state_dict(torch.load("best_model.pth")) 
model.eval()
with torch.no_grad():
    for inputs, labels in test_loader:
        inputs, labels = inputs.to(device), labels.to(device)
        outputs = model(inputs)
        _, preds = torch.max(outputs, 1)
        y_true.extend(labels.cpu().numpy())
        y_pred.extend(preds.cpu().numpy())

print("Classification Report:\n", classification_report(y_true, y_pred))
print("Confusion Matrix:\n", confusion_matrix(y_true, y_pred))