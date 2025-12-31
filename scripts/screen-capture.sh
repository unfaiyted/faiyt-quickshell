#!/bin/env bash

# Script name
SCRIPT_NAME=$(basename "$0")

# Function to display usage
usage() {
  cat << EOF
Usage: $SCRIPT_NAME <command> [options]

Commands:
  screenshot <target>     Take a screenshot
    Targets:
      selection            - Screenshot selected area
      eDP-1               - Screenshot eDP-1 display
      HDMI-A-1            - Screenshot HDMI-A-1 display
      both                - Screenshot both displays

  record <target>        Start/stop recording (MP4, NVENC H.264)
    Targets:
      selection           - Record selected area
      eDP-1              - Record eDP-1 display
      HDMI-A-1           - Record HDMI-A-1 display
      stop               - Stop current recording

  record-hq <target>     Start/stop high-quality recording (60fps, high bitrate)
    Targets:
      selection           - Record selected area in high quality
      eDP-1              - Record eDP-1 display in high quality
      HDMI-A-1           - Record HDMI-A-1 display in high quality
      stop               - Stop current recording

  record-gif <target>    Start/stop GIF recording
    Targets:
      selection           - Record selected area as GIF
      eDP-1              - Record eDP-1 display as GIF
      HDMI-A-1           - Record HDMI-A-1 display as GIF
      stop               - Stop current recording

  annotate <target>      Take screenshot and open in napkin for annotation
    Targets:
      selection           - Screenshot selected area and annotate

  status                 Check if recording is active (exit 0 if recording, 1 if not)

  convert <format>       Convert recordings
    Formats:
      webm               - Convert MP4 files to WebM
      iphone             - Convert MP4 files for iPhone
      youtube            - Convert MP4 files for YouTube (high quality)
      gif                - Convert MP4 files to GIF

Examples:
  $SCRIPT_NAME screenshot selection
  $SCRIPT_NAME record eDP-1
  $SCRIPT_NAME record-hq eDP-1
  $SCRIPT_NAME record-gif selection
  $SCRIPT_NAME record stop
  $SCRIPT_NAME annotate selection
  $SCRIPT_NAME convert gif

EOF
  exit 1
}

# Check if no arguments provided
if [ $# -eq 0 ]; then
  usage
fi

# Notification with actions for screenshots
# Usage: notify_screenshot "/path/to/image.png"
notify_screenshot() {
  local img_path="$1"
  (
    ACTION=$(notify-send -a "Screen Capture" "Screenshot Taken" "Copied to clipboard" \
      -h "string:image-path:$img_path" \
      -A "open=Open" \
      -A "delete=Delete")

    case "$ACTION" in
      open)
        xdg-open "$img_path"
        ;;
      delete)
        rm -f "$img_path"
        notify-send -a "Screen Capture" "Screenshot Deleted" "File removed"
        ;;
    esac
  ) &
}

# Notification with actions for recordings
# Usage: notify_recording "/path/to/video.mp4" [is_gif]
notify_recording() {
  local vid_path="$1"
  local is_gif="${2:-false}"
  local file_size
  file_size=$(du -h "$vid_path" | cut -f1)

  (
    local thumb_path="/tmp/recording_thumb_$(date +%s).png"
    local hint_arg=""

    # Generate thumbnail for video (not for GIF)
    if [ "$is_gif" = "false" ] && command -v ffmpeg >/dev/null 2>&1; then
      ffmpeg -i "$vid_path" -ss 00:00:01 -vframes 1 "$thumb_path" 2>/dev/null
      if [ -f "$thumb_path" ]; then
        hint_arg="-h string:image-path:$thumb_path"
      fi
    elif [ "$is_gif" = "true" ]; then
      # For GIF, use the GIF itself as the image
      hint_arg="-h string:image-path:$vid_path"
    fi

    ACTION=$(notify-send -a "Screen Capture" "Recording Saved" "Size: $file_size" \
      $hint_arg \
      -A "open=Open" \
      -A "delete=Delete")

    # Clean up thumbnail
    [ -f "$thumb_path" ] && rm -f "$thumb_path"

    case "$ACTION" in
      open)
        xdg-open "$vid_path"
        ;;
      delete)
        rm -f "$vid_path"
        notify-send -a "Screen Capture" "Recording Deleted" "File removed"
        ;;
    esac
  ) &
}

wf-recorder_check() {
  if pgrep -x "wf-recorder" >/dev/null; then
    pkill -INT -x wf-recorder
    local vid_path
    vid_path=$(cat /tmp/recording.txt 2>/dev/null)
    wl-copy < "$vid_path"
    # Wait a moment for file to be finalized, then notify
    sleep 0.5
    if [ -f "$vid_path" ]; then
      notify_recording "$vid_path" "false"
    else
      notify-send -a "Screen Capture" "Recording Stopped" "$vid_path"
    fi
    exit 0
  fi
}

# Function to record with standard settings (hardware-accelerated H.265 for large resolutions)
record_video() {
  local output_file="$1"
  shift

  # Use HEVC NVENC for NVIDIA GPUs - supports resolutions up to 8K (h264_nvenc limited to 4096px width)
  # preset=p4 is balanced speed/quality, cq=23 is good quality without huge files
  wf-recorder "$@" -f "$output_file" \
    -c hevc_nvenc \
    -p preset=p4 \
    -p rc=vbr \
    -p cq=23 \
    --pixel-format yuv420p
}

# High quality recording for YouTube (hardware-accelerated)
record_high_quality() {
  local output_file="$1"
  shift

  # Use HEVC NVENC for NVIDIA GPUs with high quality settings (supports 8K)
  # Use codec params for bitrate control instead of -b flag
  wf-recorder "$@" -f "$output_file" \
    -c hevc_nvenc \
    -r 60 \
    -p preset=p7 \
    -p rc=vbr \
    -p cq=19 \
    --pixel-format yuv420p
}

record_gif() {
  local output_file="$1"
  shift

  # Record temporary video first
  local temp_video="/tmp/gif_recording_$(date +%s).mp4"
  echo "$temp_video" >/tmp/gif_temp_video.txt

  # GIF-optimized recording (15 fps, no audio) - Use HEVC NVENC for NVIDIA GPUs (supports 8K)
  wf-recorder "$@" -f "$temp_video" \
    -c hevc_nvenc \
    -r 15 \
    --pixel-format yuv420p \
    --no-audio
  
  # After recording stops, convert to GIF
  if [ -f "$temp_video" ]; then
    notify-send -a "Screen Capture" "Converting to GIF" "Processing recording..."

    # Create high-quality GIF with optimized palette
    # Using ffmpeg with palette generation for better colors
    ffmpeg -i "$temp_video" \
      -vf "fps=15,scale=iw:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=128:stats_mode=diff[p];[s1][p]paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" \
      -loop 0 \
      "$output_file" 2>/tmp/gif_conversion.log

    if [ $? -eq 0 ]; then
      # Clean up temp file
      rm -f "$temp_video"
      rm -f /tmp/gif_temp_video.txt

      # Copy to clipboard and notify with actions
      wl-copy <"$output_file"
      notify_recording "$output_file" "true"
    else
      error=$(cat /tmp/gif_conversion.log | tail -n 5)
      notify-send -a "Screen Capture" "GIF Conversion Failed" "Error: $error"
      rm -f "$temp_video"
      rm -f /tmp/gif_temp_video.txt
    fi
  fi
}

# Parse command
COMMAND="$1"
TARGET="$2"

# Set up file paths
IMG="${HOME}/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%m-%s).png"
VID="${HOME}/Videos/Recordings/$(date +%Y-%m-%d_%H-%m-%s).mp4"

case "$COMMAND" in
  "screenshot")
    case "$TARGET" in
      "selection")
        grim -g "$(slurp)" "$IMG"
        wl-copy <"$IMG"
        notify_screenshot "$IMG"
        ;;
      "eDP-1")
        grim -c -o eDP-1 "$IMG"
        wl-copy <"$IMG"
        notify_screenshot "$IMG"
        ;;
      "HDMI-A-1")
        grim -c -o HDMI-A-1 "$IMG"
        wl-copy <"$IMG"
        notify_screenshot "$IMG"
        ;;
      "both")
        grim -c -o eDP-1 "${IMG//.png/-eDP-1.png}"
        grim -c -o HDMI-A-1 "${IMG//.png/-HDMI-A-1.png}"
        montage "${IMG//.png/-eDP-1.png}" "${IMG//.png/-HDMI-A-1.png}" -tile 2x1 -geometry +0+0 "$IMG"
        wl-copy <"$IMG"
        rm "${IMG//.png/-eDP-1.png}" "${IMG//.png/-HDMI-A-1.png}"
        notify_screenshot "$IMG"
        ;;
      *)
        echo "Error: Invalid screenshot target '$TARGET'"
        usage
        ;;
    esac
    ;;
  
  "record")
    case "$TARGET" in
      "stop")
        wf-recorder_check
        ;;
      "selection")
        wf-recorder_check
        echo "$VID" >/tmp/recording.txt
        record_video "$VID" -g "$(slurp)"
        ;;
      "eDP-1")
        wf-recorder_check
        echo "$VID" >/tmp/recording.txt
        record_video "$VID" -a -o eDP-1
        ;;
      "HDMI-A-1")
        wf-recorder_check
        echo "$VID" >/tmp/recording.txt
        record_video "$VID" -a -o HDMI-A-1
        ;;
      *)
        echo "Error: Invalid record target '$TARGET'"
        usage
        ;;
    esac
    ;;
  
  "record-hq")
    # Change file extension to mp4 for high quality recordings
    VID_HQ="${HOME}/Videos/Recordings/$(date +%Y-%m-%d_%H-%m-%s)-hq.mp4"
    
    case "$TARGET" in
      "stop")
        wf-recorder_check
        ;;
      "selection")
        wf-recorder_check
        echo "$VID_HQ" >/tmp/recording.txt
        notify-send -a "Screen Capture" "High Quality Recording" "Starting YouTube-quality recording..."
        record_high_quality "$VID_HQ" -g "$(slurp)"
        ;;
      "eDP-1")
        wf-recorder_check
        echo "$VID_HQ" >/tmp/recording.txt
        notify-send -a "Screen Capture" "High Quality Recording" "Starting on eDP-1..."
        record_high_quality "$VID_HQ" -a -o eDP-1
        ;;
      "HDMI-A-1")
        wf-recorder_check
        echo "$VID_HQ" >/tmp/recording.txt
        notify-send -a "Screen Capture" "High Quality Recording" "Starting on HDMI-A-1..."
        record_high_quality "$VID_HQ" -a -o HDMI-A-1
        ;;
      *)
        echo "Error: Invalid record-hq target '$TARGET'"
        usage
        ;;
    esac
    ;;
  
  "record-gif")
    # GIF files go to a specific location
    GIF="${HOME}/Videos/Recordings/$(date +%Y-%m-%d_%H-%m-%s).gif"
    
    case "$TARGET" in
      "stop")
        wf-recorder_check
        ;;
      "selection")
        wf-recorder_check
        echo "$GIF" >/tmp/recording.txt
        notify-send -a "Screen Capture" "GIF Recording" "Starting (15 FPS)..."
        record_gif "$GIF" -g "$(slurp)"
        ;;
      "eDP-1")
        wf-recorder_check
        echo "$GIF" >/tmp/recording.txt
        notify-send -a "Screen Capture" "GIF Recording" "Starting on eDP-1..."
        record_gif "$GIF" -o eDP-1
        ;;
      "HDMI-A-1")
        wf-recorder_check
        echo "$GIF" >/tmp/recording.txt
        notify-send -a "Screen Capture" "GIF Recording" "Starting on HDMI-A-1..."
        record_gif "$GIF" -o HDMI-A-1
        ;;
      *)
        echo "Error: Invalid record-gif target '$TARGET'"
        usage
        ;;
    esac
    ;;

  "annotate")
    case "$TARGET" in
      "selection")
        grim -g "$(slurp)" "$IMG"
        if [ -f "$IMG" ]; then
          wl-copy <"$IMG"
          ~/.local/bin/napkin --filename "$IMG" &
          # Wait for napkin to open and force fullscreen via Hyprland
          sleep 0.3
          hyprctl dispatch fullscreen 0
        fi
        ;;
      *)
        echo "Error: Invalid annotate target '$TARGET'"
        usage
        ;;
    esac
    ;;

  "status")
    # Check if wf-recorder is running
    if pgrep -x "wf-recorder" >/dev/null; then
     echo "true" 
      exit 0  
    else
      echo "false"
      exit 0  
    fi
    ;;
  
  "convert")
    case "$TARGET" in
      "webm")
        # Check if ffmpeg is installed
        if ! command -v ffmpeg >/dev/null 2>&1; then
          notify-send -a "Screen Capture" "Error" "ffmpeg is not installed"
          exit 1
        fi

        RECORDING_DIR="${HOME}/Videos/Recordings"
        CONVERTED=0
        TOTAL=0

        for mp4_file in "${RECORDING_DIR}"/*.mp4; do
          if [ -f "$mp4_file" ]; then
            TOTAL=$((TOTAL+1))
            webm_file="${mp4_file%.mp4}.webm"

            # Check if webm version doesn't already exist
            if [ ! -f "$webm_file" ]; then
              ffmpeg -y -i "$mp4_file" -c:v libvpx -b:v 1M -c:a libvorbis "$webm_file" 2>/tmp/ffmpeg_error.log

              if [ $? -eq 0 ]; then
                CONVERTED=$((CONVERTED+1))
                notify-send -a "Screen Capture" "Converted to WebM" "$(basename "$mp4_file")"
              else
                error=$(cat /tmp/ffmpeg_error.log | tail -n 5)
                notify-send -a "Screen Capture" "Conversion Failed" "Error: $error"
              fi
            fi
          fi
        done

        if [ $TOTAL -eq 0 ]; then
          notify-send -a "Screen Capture" "WebM Conversion" "No MP4 files found"
        else
          notify-send -a "Screen Capture" "WebM Conversion Complete" "Converted $CONVERTED of $TOTAL files"
        fi
        ;;

      "iphone")
        # Check if ffmpeg is installed
        if ! command -v ffmpeg >/dev/null 2>&1; then
          notify-send -a "Screen Capture" "Error" "ffmpeg is not installed"
          exit 1
        fi

        RECORDING_DIR="${HOME}/Videos/Recordings"
        CONVERTED=0
        SKIPPED_IPHONE=0
        SKIPPED_EXISTING=0
        TOTAL_FILES=0

        for mp4_file in "${RECORDING_DIR}"/*.mp4; do
          if [ -f "$mp4_file" ]; then
            TOTAL_FILES=$((TOTAL_FILES+1))
            base_filename=$(basename "$mp4_file")

            # Skip files with "iphone" in the filename
            if [[ $base_filename == *"iphone"* ]]; then
              SKIPPED_IPHONE=$((SKIPPED_IPHONE+1))
              continue
            fi

            iphone_file="${mp4_file%.mp4}-iphone.mp4"

            # Check if iPhone version doesn't already exist
            if [ ! -f "$iphone_file" ]; then
              ffmpeg -y -i "$mp4_file" -vcodec h264 -acodec aac "$iphone_file" 2>/tmp/ffmpeg_error.log

              if [ $? -eq 0 ]; then
                CONVERTED=$((CONVERTED+1))
                notify-send -a "Screen Capture" "Converted for iPhone" "$(basename "$mp4_file")"
              else
                error=$(cat /tmp/ffmpeg_error.log | tail -n 5)
                notify-send -a "Screen Capture" "Conversion Failed" "Error: $error"
              fi
            else
              SKIPPED_EXISTING=$((SKIPPED_EXISTING+1))
            fi
          fi
        done

        if [ $TOTAL_FILES -eq 0 ]; then
          notify-send -a "Screen Capture" "iPhone Conversion" "No MP4 files found"
        else
          notify-send -a "Screen Capture" "iPhone Conversion Complete" "Converted: $CONVERTED files"
        fi
        ;;

      "youtube")
        # Check if ffmpeg is installed
        if ! command -v ffmpeg >/dev/null 2>&1; then
          notify-send -a "Screen Capture" "Error" "ffmpeg is not installed"
          exit 1
        fi

        RECORDING_DIR="${HOME}/Videos/Recordings"
        CONVERTED=0
        SKIPPED_YOUTUBE=0
        SKIPPED_EXISTING=0
        TOTAL_FILES=0

        for video_file in "${RECORDING_DIR}"/*.mp4; do
          if [ -f "$video_file" ]; then
            TOTAL_FILES=$((TOTAL_FILES+1))
            base_filename=$(basename "$video_file")

            # Skip files already marked as YouTube uploads
            if [[ $base_filename == *"youtube"* ]]; then
              SKIPPED_YOUTUBE=$((SKIPPED_YOUTUBE+1))
              continue
            fi

            youtube_file="${video_file%.mp4}-youtube.mp4"

            # Check if YouTube version doesn't already exist
            if [ ! -f "$youtube_file" ]; then
              notify-send -a "Screen Capture" "Converting for YouTube" "Processing: $(basename "$video_file")"

              ffmpeg -y -i "$video_file" \
                -c:v libx264 \
                -profile:v high \
                -preset slow \
                -crf 18 \
                -pix_fmt yuv420p \
                -c:a aac \
                -b:a 384k \
                -movflags +faststart \
                "$youtube_file" 2>/tmp/ffmpeg_error.log

              if [ $? -eq 0 ]; then
                CONVERTED=$((CONVERTED+1))
                file_size=$(du -h "$youtube_file" | cut -f1)
                notify-send -a "Screen Capture" "YouTube Conversion Success" "$(basename "$youtube_file") ($file_size)"
              else
                error=$(cat /tmp/ffmpeg_error.log | tail -n 5)
                notify-send -a "Screen Capture" "YouTube Conversion Failed" "Error: $error"
              fi
            else
              SKIPPED_EXISTING=$((SKIPPED_EXISTING+1))
            fi
          fi
        done

        if [ $TOTAL_FILES -eq 0 ]; then
          notify-send -a "Screen Capture" "YouTube Conversion" "No MP4 files found"
        else
          notify-send -a "Screen Capture" "YouTube Conversion Complete" "Converted: $CONVERTED files"
        fi
        ;;

      "gif")
        # Check if ffmpeg is installed
        if ! command -v ffmpeg >/dev/null 2>&1; then
          notify-send -a "Screen Capture" "Error" "ffmpeg is not installed"
          exit 1
        fi

        RECORDING_DIR="${HOME}/Videos/Recordings"
        CONVERTED=0
        SKIPPED_GIF=0
        SKIPPED_EXISTING=0
        TOTAL_FILES=0

        for video_file in "${RECORDING_DIR}"/*.mp4; do
          if [ -f "$video_file" ]; then
            TOTAL_FILES=$((TOTAL_FILES+1))
            base_filename=$(basename "$video_file")

            gif_file="${video_file%.mp4}.gif"

            # Check if GIF version doesn't already exist
            if [ ! -f "$gif_file" ]; then
              notify-send -a "Screen Capture" "Converting to GIF" "Processing: $(basename "$video_file")"

              # Get video dimensions for scaling
              width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=s=x:p=0 "$video_file")

              # Scale down if wider than 800px to keep file size reasonable
              if [ "$width" -gt 800 ]; then
                scale_filter="scale=800:-1:flags=lanczos,"
              else
                scale_filter=""
              fi

              # Create high-quality GIF with optimized palette
              ffmpeg -i "$video_file" \
                -vf "${scale_filter}fps=15,split[s0][s1];[s0]palettegen=max_colors=256:stats_mode=diff[p];[s1][p]paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" \
                -loop 0 \
                "$gif_file" 2>/tmp/ffmpeg_error.log

              if [ $? -eq 0 ]; then
                CONVERTED=$((CONVERTED+1))
                file_size=$(du -h "$gif_file" | cut -f1)
                notify-send -a "Screen Capture" "GIF Created" "$(basename "$gif_file") ($file_size)" -h "string:image-path:$gif_file"
              else
                error=$(cat /tmp/ffmpeg_error.log | tail -n 5)
                notify-send -a "Screen Capture" "GIF Conversion Failed" "Error: $error"
              fi
            else
              SKIPPED_EXISTING=$((SKIPPED_EXISTING+1))
            fi
          fi
        done

        if [ $TOTAL_FILES -eq 0 ]; then
          notify-send -a "Screen Capture" "GIF Conversion" "No MP4 files found"
        else
          notify-send -a "Screen Capture" "GIF Conversion Complete" "Converted: $CONVERTED files"
        fi
        ;;
      
      *)
        echo "Error: Invalid convert format '$TARGET'"
        usage
        ;;
    esac
    ;;
  
  *)
    echo "Error: Invalid command '$COMMAND'"
    usage
    ;;
esac
