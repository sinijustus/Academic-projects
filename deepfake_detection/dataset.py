import os
from torch.utils.data import Dataset
from PIL import Image
from torchvision import transforms
import torch

class DeepFakeDataset(Dataset):
    def __init__(self, frames_dir, labels, transform=None, num_frames=10):
        """
        Args:
            frames_dir (str): Path to the directory containing the video frames.
            labels (dict): Dictionary containing labels for 'real' and 'fake' videos.
            transform (callable, optional): A function/transform to apply to the frames.
            num_frames (int): Number of frames to sample from each video.
        """
        self.frames_dir = frames_dir
        self.labels = labels
        self.transform = transform
        self.num_frames = num_frames
        self.data = self._load_data()  # Load the data during initialization

    def _load_data(self):
        """
        Loads and processes the frames directly from the `real` or `fake` folders.

        Returns:
            list: A list of tuples (frame_paths, label).
        """
        data = []
        valid_extensions = ('.jpg', '.jpeg', '.png')  # Image file extensions

        for label_name, label in self.labels.items():
            label_dir = os.path.join(self.frames_dir, label_name)
            print(f"Checking directory: {label_dir}")  # Debugging output

            if not os.path.exists(label_dir):
                print(f"Directory {label_dir} does not exist.")  # Debugging output
                continue

            # Load frames directly from the subfolders inside the `real` or `fake` folder
            frame_paths = []
            for subfolder in sorted(os.listdir(label_dir)):
                subfolder_path = os.path.join(label_dir, subfolder)
                if os.path.isdir(subfolder_path):
                    # Collect image files from the subfolder that match the naming pattern (e.g., frame_*.jpg)
                    frames = sorted([os.path.join(subfolder_path, f) for f in os.listdir(subfolder_path) if f.lower().endswith(valid_extensions)])
                    frame_paths.extend(frames)

            if len(frame_paths) == 0:
                print(f"No valid frames found in {label_name}")
                continue

            # Sample frames up to the specified `num_frames`
            frame_paths = frame_paths[:self.num_frames]
            data.append((frame_paths, label))

        print(f"Total videos loaded: {len(data)}")  # Debugging output
        return data

    def __len__(self):
        """Returns the size of the dataset."""
        return len(self.data)

    def __getitem__(self, idx):
        """
        Args:
            idx (int): Index of the sample to retrieve.
        
        Returns:
            tuple: A tuple (frames_tensor, label) where:
                - frames_tensor (Tensor): A tensor of shape (num_frames, 3, 224, 224).
                - label (Tensor): A tensor containing the label (0 for real, 1 for fake).
        """
        frame_paths, label = self.data[idx]
        frames = [Image.open(frame_path).convert('RGB') for frame_path in frame_paths]

        if self.transform:
            frames = [self.transform(frame) for frame in frames]

        frames_tensor = torch.stack(frames)

        # Sanity check: Ensure the frames tensor has the shape (num_frames, 3, 224, 224)
        assert frames_tensor.shape == (self.num_frames, 3, 224, 224), \
            f"Expected tensor shape ({self.num_frames}, 3, 224, 224), but got {frames_tensor.shape}"

        return frames_tensor, torch.tensor(label)

# Label mappings for 'real' and 'fake' videos
train_labels = {
    'real': 0,
    'fake': 1,
}

# Example of creating the dataset with transforms
transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
])

# Initialize the dataset
dataset = DeepFakeDataset(
    frames_dir='E:/Project/deepfake detection/data/frames',
    labels=train_labels,
    transform=transform,
    num_frames=10
)

# Test by printing the length of the dataset
print(f"Dataset length: {len(dataset)}")

# Get the first item from the dataset
frames_tensor, label = dataset[0]

# Print the shape of the frames tensor and the label
print(f"Frames tensor shape: {frames_tensor.shape}")
print(f"Label: {label}")
