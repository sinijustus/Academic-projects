import cv2
import os
import torch
from torchvision import transforms

def extract_frames(filepath, output_dir, num_frames=10):
    cap = cv2.VideoCapture(filepath)
    if not cap.isOpened():
        raise ValueError("Failed to open video file")
    
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    frame_interval = max(total_frames // num_frames, 1)
    
    frames_extracted = 0
    for i in range(num_frames):
        frame_pos = min(i * frame_interval, total_frames - 1)
        cap.set(cv2.CAP_PROP_POS_FRAMES, frame_pos)
        ret, frame = cap.read()
        
        if ret:
            output_path = os.path.join(output_dir, f'frame_{i}.jpg')
            cv2.imwrite(output_path, frame)
            frames_extracted += 1
    
    cap.release()
    if frames_extracted == 0:
        raise ValueError("No frames were extracted from the video")

def load_and_preprocess_video(filepath):
    temp_frames_dir = os.path.join('uploads', 'temp_frames')
    os.makedirs(temp_frames_dir, exist_ok=True)

    try:
        extract_frames(filepath, temp_frames_dir, num_frames=10)
        
        processed_frames = []
        transform = transforms.Compose([
            transforms.ToPILImage(),
            transforms.Resize((224, 224)),
            transforms.ToTensor(),
            transforms.Normalize(
                mean=[0.485, 0.456, 0.406],
                std=[0.229, 0.224, 0.225]
            )
        ])
        
        for i in range(10):
            frame_path = os.path.join(temp_frames_dir, f'frame_{i}.jpg')
            frame = cv2.imread(frame_path)
            if frame is None:
                continue
            frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            frame = transform(frame)
            processed_frames.append(frame)

        if not processed_frames:
            raise ValueError("No frames were successfully processed")
        
        frames_tensor = torch.stack(processed_frames)
        return frames_tensor
        
    finally:
        for file in os.listdir(temp_frames_dir):
            os.remove(os.path.join(temp_frames_dir, file))
        os.rmdir(temp_frames_dir) 