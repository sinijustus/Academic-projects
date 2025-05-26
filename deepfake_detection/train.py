import os
import torch
import torch.optim as optim
import torch.nn as nn
from torch.utils.data import DataLoader
from torchvision import transforms
from resnext_lstm_model import SimpleResNetLSTMModel  # Ensure this model file is available
from dataset import DeepFakeDataset  # Ensure the correct path for DeepFakeDataset

# Device configuration
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# Hyperparameters
batch_size = 16  # Reduced batch size for better generalization
learning_rate = 0.0001
num_epochs = 100
weight_decay = 0.01  # Add L2 regularization

# Data transformations
transform = transforms.Compose([
    transforms.RandomHorizontalFlip(),
    transforms.RandomRotation(10),
    transforms.ColorJitter(brightness=0.2, contrast=0.2, saturation=0.2, hue=0.1),
    transforms.Resize((224, 224)),  # Resize to 224x224
    transforms.ToTensor(),  # Convert to tensor
])

# Load training data function
def load_training_data():
    try:
        print("Loading training data...")
        # Specify the paths to your frame directories
        train_frames_dir = 'E:/Project/deepfake detection/data/frames'  # Modify this to your data path
        labels = {
            'real': 0,
            'fake': 1,
        }

        # Create the dataset
        dataset = DeepFakeDataset(
            frames_dir=train_frames_dir,
            labels=labels,
            transform=transform,
            num_frames=10  # Number of frames to sample per video
        )

        # Split the dataset into train and validation
        train_size = int(0.8 * len(dataset))
        val_size = len(dataset) - train_size
        train_dataset, val_dataset = torch.utils.data.random_split(dataset, [train_size, val_size])

        # Create data loaders
        train_loader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True)
        val_loader = DataLoader(val_dataset, batch_size=batch_size, shuffle=False)

        print("Training data loaded successfully.")
        return train_loader, val_loader
    except Exception as e:
        print(f"Error loading training data: {e}")
        return None, None

# Training function
def train_model_if_needed(force_train=False, num_epochs=5):
    model_path = 'best_model.pth'
    
    if os.path.exists(model_path) and not force_train:
        print("Pre-trained model found. Skipping training.")
        return
    
    print("Starting model training...")

    # Load data only when training
    train_loader, val_loader = load_training_data()
    
    if train_loader is None or len(train_loader) == 0:
        print("No training data available. Skipping training.")
        return
    
    try:
        # Initialize model and training components
        print("Initializing model...")
        model = SimpleResNetLSTMModel(num_classes=1).to(device)
        criterion = nn.BCEWithLogitsLoss()  # Binary classification
        optimizer = optim.AdamW(model.parameters(), 
                               lr=learning_rate, 
                               weight_decay=weight_decay)
        print("Model initialized.")

        # Add learning rate scheduler
        scheduler = optim.lr_scheduler.ReduceLROnPlateau(optimizer, 
                                                        mode='min', 
                                                        factor=0.1, 
                                                        patience=5, 
                                                        verbose=True)

        # Training loop
        for epoch in range(num_epochs):
            model.train()
            running_loss = 0.0
            for batch_idx, (frames, labels) in enumerate(train_loader):
                frames, labels = frames.to(device), labels.to(device)
                optimizer.zero_grad()

                # Ensure the frames have the correct shape for the model
                if frames.dim() != 5:  # Ensure it's (batch_size, num_frames, channels, height, width)
                    print(f"Warning: Input frame shape mismatch. Expected 5 dimensions, got {frames.dim()}")
                    continue

                # Forward pass
                outputs = model(frames)  # Outputs should have shape [batch_size, 1]

                # Ensure the output and labels have the same shape
                outputs = outputs.squeeze(1)  # Remove unnecessary dimensions (should have shape [batch_size])

                # Make sure labels are float for BCEWithLogitsLoss
                loss = criterion(outputs, labels.float())  # Binary cross entropy loss with logits
                loss.backward()
                optimizer.step()
                
                running_loss += loss.item()
                if batch_idx % 10 == 0:
                    print(f'Epoch: {epoch+1}/{num_epochs}, Batch: {batch_idx}, Loss: {loss.item():.4f}')
            
            avg_loss = running_loss / len(train_loader)
            print(f'Epoch [{epoch+1}/{num_epochs}], Average Loss: {avg_loss:.4f}')
        
        # Save the model
        torch.save(model.state_dict(), model_path)
        print(f"Model saved to {model_path}")
        
    except Exception as e:
        print(f"Error during training: {e}")

def validate(model, val_loader, criterion, device):
    model.eval()
    val_loss = 0
    correct = 0
    total = 0
    
    with torch.no_grad():
        for frames, labels in val_loader:
            frames, labels = frames.to(device), labels.to(device)
            outputs = model(frames)
            loss = criterion(outputs.squeeze(), labels.float())
            val_loss += loss.item()
            
            predicted = (torch.sigmoid(outputs.squeeze()) > 0.5).float()
            total += labels.size(0)
            correct += (predicted == labels).sum().item()
    
    accuracy = 100 * correct / total
    return val_loss / len(val_loader), accuracy

if __name__ == "__main__":
    train_model_if_needed(force_train=True, num_epochs=num_epochs)
