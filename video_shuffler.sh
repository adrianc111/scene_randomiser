#!/usr/bin/env bash
# Video Shuffler CLI - Split videos into scenes and shuffle them
set -euo pipefail

# Show banner
echo "Video Shuffler CLI"
echo "==================="

# Check for required dependencies
check_dependencies() {
  if ! command -v ffmpeg &> /dev/null; then
    echo "Error: ffmpeg is not installed or not in PATH" >&2
    return 1
  fi

  if ! command -v scenedetect &> /dev/null; then
    echo "Error: scenedetect is not installed. Install with: pip install scenedetect" >&2
    return 1
  fi

  # Check for GNU shuf or macOS alternative
  if ! command -v shuf &> /dev/null && ! command -v gshuf &> /dev/null; then
    echo "Warning: Neither 'shuf' nor 'gshuf' found. Will use internal shuffling method." >&2
  fi

  return 0
}

# Function to show help
show_help() {
  cat <<EOF
Usage: $(basename "$0") <command> [options]

Commands:
  split    Split a video into scenes
  shuffle  Randomly concatenate video clips from a directory
  full     Both split video into scenes and create shuffled version

Options for 'split':
  -s, --source <input_video.mp4>  Path to the source video file (required)
  -o, --output <output_dir>       Output directory for scenes (default: ./scenes)

Options for 'shuffle':
  -s, --source <clips_dir>        Directory containing video clips (required)
  -o, --output <output_file.mp4>  Output file for shuffled video (required)

Options for 'full':
  -s, --source <input_video.mp4>  Path to the source video file (required)
  -o, --output <output_file.mp4>  Output file for shuffled video (default: input_shuffled.mp4)
  -k, --keep-scenes               Keep extracted scene clips after processing

General options:
  -h, --help                      Show this help message and exit
EOF
  exit 1
}

# Function to shuffle videos in a directory
shuffle_videos() {
  local source_dir="$1"
  local output_file="$2"

  if [[ ! -d "$source_dir" ]]; then
    echo "Error: Source directory '$source_dir' does not exist" >&2
    return 1
  fi

  # Create output directory if it doesn't exist
  mkdir -p "$(dirname "$output_file")"

  # Count available video files
  local video_count=$(find "$source_dir" -name "*.mp4" | wc -l)
  if [[ $video_count -eq 0 ]]; then
    echo "Error: No .mp4 files found in '$source_dir'" >&2
    return 1
  fi

  echo "Found $video_count video clips to shuffle"

  # Create temporary file for ffmpeg concat
  local temp_file=$(mktemp)

  # Get a list of videos and shuffle them
  if command -v shuf &> /dev/null; then
    # Use GNU shuf if available
    find "$source_dir" -name "*.mp4" | shuf | while read -r video; do
      echo "file '$video'" >> "$temp_file"
    done
  elif command -v gshuf &> /dev/null; then
    # Use gshuf on macOS (from coreutils)
    find "$source_dir" -name "*.mp4" | gshuf | while read -r video; do
      echo "file '$video'" >> "$temp_file"
    done
  else
    # Fallback to a more basic method
    # Convert find results to array
    mapfile -t videos < <(find "$source_dir" -name "*.mp4")
    # Get random order of indices
    for i in $(seq 0 $((${#videos[@]} - 1)) | sort -R); do
      echo "file '${videos[$i]}'" >> "$temp_file"
    done
  fi

  echo "Merging shuffled clips into $output_file..."

  # Concatenate videos using FFmpeg
  if ffmpeg -f concat -safe 0 -i "$temp_file" -c copy "$output_file"; then
    echo "Successfully created shuffled video: $output_file"
    rm "$temp_file"
    return 0
  else
    echo "Error during FFmpeg concatenation" >&2
    rm "$temp_file"
    return 1
  fi
}

# Function to split video into scenes
split_video() {
  local input_file="$1"
  local output_dir="$2"

  if [[ ! -f "$input_file" ]]; then
    echo "Error: Input file '$input_file' does not exist" >&2
    return 1
  fi

  # Create output directory
  mkdir -p "$output_dir"

  echo "Detecting and extracting scenes from $input_file..."

  # Use scenedetect to split the video
  if scenedetect -i "$input_file" detect-content split-video -o "$output_dir"; then
    local scene_count=$(find "$output_dir" -name "*Scene-*.mp4" | wc -l)
    echo "Successfully extracted $scene_count scenes to $output_dir"
    return 0
  else
    echo "Error during scene detection" >&2
    return 1
  fi
}

# Function to do full process: split and shuffle
full_process() {
  local input_file="$1"
  local output_file="$2"
  local keep_scenes="$3"

  # Create a temporary directory for scenes if not keeping them
  if [[ "$keep_scenes" == "false" ]]; then
    local scenes_dir=$(mktemp -d)
    trap 'rm -rf "$scenes_dir"' EXIT
  else
    # Use a subdirectory next to output file
    local scenes_dir="$(dirname "$output_file")/scenes"
    mkdir -p "$scenes_dir"
  fi

  # Step 1: Split video into scenes
  if ! split_video "$input_file" "$scenes_dir"; then
    return 1
  fi

  # Step 2: Shuffle and concatenate scenes
  if shuffle_videos "$scenes_dir" "$output_file"; then
    if [[ "$keep_scenes" == "true" ]]; then
      echo "Scene clips preserved in: $scenes_dir"
    fi
    return 0
  else
    return 1
  fi
}

# Check if no arguments provided
if [[ $# -eq 0 ]]; then
  show_help
fi

# Check dependencies
if ! check_dependencies; then
  exit 1
fi

# Parse command
COMMAND="$1"
shift

# Default values
SOURCE=""
OUTPUT=""
KEEP_SCENES="false"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--source)
      SOURCE="$2"
      shift 2
      ;;
    -o|--output)
      OUTPUT="$2"
      shift 2
      ;;
    -k|--keep-scenes)
      KEEP_SCENES="true"
      shift
      ;;
    -h|--help)
      show_help
      ;;
    *)
      echo "Unknown option: $1" >&2
      show_help
      ;;
  esac
done

# Execute command
case "$COMMAND" in
  split)
    # Validate arguments
    if [[ -z "$SOURCE" ]]; then
      echo "Error: --source is required for split command" >&2
      show_help
    fi

    # Set default output directory if not specified
    if [[ -z "$OUTPUT" ]]; then
      OUTPUT="./scenes"
    fi

    # Execute split
    if ! split_video "$SOURCE" "$OUTPUT"; then
      exit 1
    fi
    ;;

  shuffle)
    # Validate arguments
    if [[ -z "$SOURCE" ]]; then
      echo "Error: --source directory is required for shuffle command" >&2
      show_help
    fi

    if [[ -z "$OUTPUT" ]]; then
      echo "Error: --output file is required for shuffle command" >&2
      show_help
    fi

    # Execute shuffle
    if ! shuffle_videos "$SOURCE" "$OUTPUT"; then
      exit 1
    fi
    ;;

  full)
    # Validate arguments
    if [[ -z "$SOURCE" ]]; then
      echo "Error: --source is required for full command" >&2
      show_help
    fi

    # Set default output file if not specified
    if [[ -z "$OUTPUT" ]]; then
      # Use input filename with _shuffled suffix
      OUTPUT="$(dirname "$SOURCE")/$(basename "${SOURCE%.*}")_shuffled.mp4"
    fi

    # Execute full process
    if ! full_process "$SOURCE" "$OUTPUT" "$KEEP_SCENES"; then
      exit 1
    fi
    ;;

  help)
    show_help
    ;;

  *)
    echo "Unknown command: $COMMAND" >&2
    show_help
    ;;
esac

exit 0