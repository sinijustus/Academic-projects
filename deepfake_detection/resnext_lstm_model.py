import torch
import torch.nn as nn
import torchvision.models as models
from dataloader import initialize_data_loaders

class SimpleResNetLSTMModel(nn.Module):
    def __init__(self, num_classes=1):
        super(SimpleResNetLSTMModel, self).__init__()
        
        # Load pre-trained ResNeXt
        self.resnext = models.resnext50_32x4d(weights="IMAGENET1K_V1")
        
        # Freeze early layers
        for param in list(self.resnext.parameters())[:-2]:
            param.requires_grad = False
            
        # Remove the last fully connected layer
        feature_size = self.resnext.fc.in_features
        self.resnext.fc = nn.Identity()
        
        # Simpler LSTM configuration matching the saved model
        self.lstm = nn.LSTM(
            input_size=feature_size,
            hidden_size=512,  # Changed from 1024
            num_layers=2,     # Changed from 3
            batch_first=True,
            dropout=0.3,
            bidirectional=False  # Changed from True
        )
        
        # Simple FC layer instead of attention and complex classifier
        self.fc = nn.Linear(512, num_classes)  # Changed from complex classifier
        
    def forward(self, x):
        batch_size, num_frames, c, h, w = x.size()
        
        # Process each frame through ResNeXt
        x = x.view(batch_size * num_frames, c, h, w)
        features = self.resnext(x)
        
        # Reshape for LSTM
        features = features.view(batch_size, num_frames, -1)
        
        # Pass through LSTM
        lstm_out, _ = self.lstm(features)
        
        # Get final frame representation
        final_out = lstm_out[:, -1, :]
        
        # Pass through final FC layer
        output = self.fc(final_out)
        
        return output

if __name__ == "__main__":
    # Test the model
    data_dir = "E:/Project/Deepfake detection/data/"
    train_loader, val_loader, test_loader = initialize_data_loaders(data_dir)
    
    if train_loader:
        model = SimpleResNetLSTMModel()
        device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        model = model.to(device)
        
        # Test forward pass
        for frames, labels in train_loader:
            frames = frames.to(device)
            outputs = model(frames)
            print(f"Input shape: {frames.shape}")
            print(f"Output shape: {outputs.shape}")
            break
