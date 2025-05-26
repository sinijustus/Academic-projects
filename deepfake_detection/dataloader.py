import os
import cv2
import numpy as np
import torch
from torch.utils.data import Dataset, DataLoader
from torchvision import transforms
from PIL import Image

class DeepFakeDataset(Dataset):
    def __init__(self, frames_dir, transform=None, num_frames=10):
        self.frames_dir = frames_dir
        self.transform = transform
        self.num_frames = num_frames
        self.data = self._load_data()

    def _load_data(self):
        data = []
        if not os.path.exists(self.frames_dir):
            print(f"Creating dummy data as {self.frames_dir} not found")
            return self._create_dummy_data()

        # Original data loading process here if data exists in frames_dir
        # Ensure this method appends (frame_paths, label) to data
        return data

    def _create_dummy_data(self):
        dummy_data = []
        for idx in range(100):
            frames = np.random.randint(
                0, 255, (self.num_frames, 224, 224, 3), dtype=np.uint8
            )
            label = idx % 2  # Alternating between real (0) and fake (1)
            dummy_data.append((frames, label))
        return dummy_data

    def __len__(self):
        return len(self.data)

    def __getitem__(self, idx):
        frames, label = self.data[idx]
        
        # Transform each frame individually if transform is set
        if self.transform:
            frames = [self.transform(Image.fromarray(frame)) for frame in frames]

        # Stack transformed frames along a new dimension to create a tensor
        frames_tensor = torch.stack(frames)
        
        return frames_tensor, torch.tensor(label, dtype=torch.float32)

def initialize_data_loaders(data_dir, batch_size=32, num_frames=10):
    transform = transforms.Compose([
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
    ])

    dataset = DeepFakeDataset(
        frames_dir=data_dir,
        transform=transform,
        num_frames=num_frames
    )

    total_size = len(dataset)
    train_size = int(0.7 * total_size)
    val_size = int(0.15 * total_size)
    test_size = total_size - train_size - val_size

    train_dataset, val_dataset, test_dataset = torch.utils.data.random_split(
        dataset, [train_size, val_size, test_size]
    )

    train_loader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True, num_workers=2, pin_memory=True)
    val_loader = DataLoader(val_dataset, batch_size=batch_size, shuffle=False, num_workers=2, pin_memory=True)
    test_loader = DataLoader(test_dataset, batch_size=batch_size, shuffle=False, num_workers=2, pin_memory=True)

    return train_loader, val_loader, test_loader

if __name__ == "__main__":
    data_dir = "E:/Project/Deepfake detection/data/frames"

    if not os.path.exists(data_dir):
        os.makedirs(data_dir)
        print(f"Created directory: {data_dir}")

    dataset = DeepFakeDataset(frames_dir=data_dir)
    print(f"Dataset size: {len(dataset)}")

    frames, label = dataset[0]
    print(f"Sample shape: {frames.shape}, Label: {label}")

    print("\nDirectory contents:")
    contents = os.listdir(data_dir) if os.path.exists(data_dir) else []
    for item in contents:
        print(f"- {item}")
