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

# Python base image kullanarak gerekli bağımlılıkları yükle
FROM python:3.10-slim AS python-deps
WORKDIR /app
COPY ["FaceCrimPenguin/Predict", "/app/predict"]
RUN pip install torch torchvision pillow opencv-python

# .NET runtime ve Python'u içeren bir temel imaj kullan
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS final
WORKDIR /app
COPY --from=publish /app/publish .
COPY --from=python-deps /usr/local/lib/python3.10 /usr/local/lib/python3.10
COPY --from=python-deps /usr/local/bin /usr/local/bin
COPY --from=python-deps /app/predict /app/predict

ENTRYPOINT ["dotnet", "FaceCrimPenguin.dll"]