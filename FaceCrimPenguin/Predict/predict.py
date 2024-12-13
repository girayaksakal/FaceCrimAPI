# -*- coding: utf-8 -*-
import torch
from torchvision import models, transforms
from PIL import Image
import sys
import cv2
import os

model = models.resnet18(pretrained=False)
num_ftrs = model.fc.in_features
model.fc = torch.nn.Linear(num_ftrs, 3)
model.load_state_dict(torch.load("/app/predict/new_resnet18_terror_model.pth", map_location=torch.device('cpu')))
model.eval()

class_names = ['F-ORG', 'INNOCENT', 'P-ORG']

def predict(image_path):
    image = Image.open(image_path).convert('RGB')
    
    # Siyah beyaz yap
    image = image.convert('L')
    
    # Yüze odakla
    face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
    img = cv2.imread(image_path)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    
    faces = face_cascade.detectMultiScale(gray, scaleFactor=1.1, minNeighbors=5)
    if len(faces) > 0:
        (x, y, w, h) = faces[0]
        img_cropped = img[y:y+h, x:x+w]
        cv2.imwrite("cropped_face.jpg", img_cropped)  # Kırpılmış yüzü kaydet
        image = Image.open("cropped_face.jpg").convert('RGB')

    transform = transforms.Compose([
        transforms.Resize((224, 224)),
        transforms.ToTensor(),
        transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
    ])

    image = transform(image).unsqueeze(0)  

    outputs = model(image)
    _, preds = torch.max(outputs, 1) 
    return class_names[preds[0]]

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Lütfen bir görüntü dosya yolu sağlayın.")
    else:
        image_path = sys.argv[1]
        prediction = predict(image_path)
        print(prediction)
