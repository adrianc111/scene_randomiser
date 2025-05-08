# 🎥 Video Randomiser

**Video Randomiser** takes any MP4 video, splits it at scene changes, and reassembles the clips in a random order.

## 🔧 Features

- Automatically detects scene changes.
- Cuts the video into separate clips.
- Recombines the clips in random order into a new video.

## 🖥️ Setup (macOS)

1. Open Terminal and run:

    ```bash
    git clone https://github.com/adrianc111/scene_randomiser
    cd scene_randomiser
    ./dependencies/install_deps.sh
    pip install -r requirements.txt
    ```

## 🖥️ Run the script

1. Split Video Only

   This will only detect scene changes and extract individual clips.

   ```bash
   ./video_shuffler.sh split --source video.mp4 --output scenes_folder
   ```

2. Shuffle Only

   This takes existing video clips from a folder and creates a new video with them in random order.

   ```bash
   ./video_shuffler.sh shuffle --source scenes_folder --output shuffled.mp4
   ```

3. Full Process

   This performs both operations: splits the video into scenes and then creates a shuffled version.

   ```bash
   ./video_shuffler.sh full --source video.mp4 --output shuffled.mp4 --keep-scenes
   ```

## 📝 Example

If you run:

```bash
./video_shuffler.sh full --source /Users/adrianc111/Downloads/myfile.mp4 --output /Users/adrianc111/Downloads/shuffled.mp4 --keep-scenes
