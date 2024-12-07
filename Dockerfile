# .NET SDK içeren bir temel imaj kullan
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY ["FaceCrimPenguin/FaceCrimPenguin.csproj", "FaceCrimPenguin/"]
RUN dotnet restore "FaceCrimPenguin/FaceCrimPenguin.csproj"
COPY . .
WORKDIR "/src/FaceCrimPenguin"
RUN dotnet build "FaceCrimPenguin.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "FaceCrimPenguin.csproj" -c Release -o /app/publish

# .NET runtime ve Python'u içeren bir temel imaj kullan
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS final
WORKDIR /app

# Python'u ve gerekli bağımlılıkları yükle
RUN apt-get update && apt-get install -y python3.10 python3-pip python3-venv libgl1 libglib2.0-0

# Python sanal ortamını oluştur ve bağımlılıkları yükle
COPY ["FaceCrimPenguin/Predict", "/app/predict"]
COPY ["FaceCrimPenguin/Predict/new_resnet18_terror_model.pth", "/app/predict/new_resnet18_terror_model.pth"]
RUN python3 -m venv /app/venv
RUN /app/venv/bin/pip install torch torchvision pillow opencv-python

# Uygulama dosyalarını kopyala
COPY --from=publish /app/publish .

# Sanal ortamı PATH'e ekle
ENV PATH="/app/venv/bin:$PATH"

ENTRYPOINT ["dotnet", "FaceCrimPenguin.dll"]