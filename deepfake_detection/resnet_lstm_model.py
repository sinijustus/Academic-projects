import torch
import torch.nn as nn
import torchvision.models as models

class ResNetLSTMModel(nn.Module):
    def __init__(self, num_classes=1):
        super(ResNetLSTMModel, self).__init__()
        
        # Load pre-trained ResNet
        self.resnet = models.resnet50(weights="IMAGENET1K_V1")
        
        # Freeze early layers
        for param in list(self.resnet.parameters())[:-2]:
            param.requires_grad = False
            
        # Remove the last fully connected layer
        feature_size = self.resnet.fc.in_features
        self.resnet.fc = nn.Identity()
        
        # LSTM configuration
        self.lstm = nn.LSTM(
            input_size=feature_size,
            hidden_size=512,
            num_layers=2,
            batch_first=True,
            dropout=0.3,
            bidirectional=False
        )
        
        # Fully connected layer for classification
        self.fc = nn.Linear(512, num_classes)
        
    def forward(self, x):
        batch_size, num_frames, c, h, w = x.size()
        
        # Process each frame through ResNet
        x = x.view(batch_size * num_frames, c, h, w)
        features = self.resnet(x)
        
        # Reshape for LSTM
        features = features.view(batch_size, num_frames, -1)
        
        # Pass through LSTM
        lstm_out, _ = self.lstm(features)
        
        # Get final frame representation
        final_out = lstm_out[:, -1, :]
        
        # Pass through final FC layer
        output = self.fc(final_out)
        
        return output 