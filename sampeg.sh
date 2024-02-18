#!/bin/bash

# Function to check if NVENC is supported
check_nvenc_support() {
    if ffmpeg -hide_banner -encoders 2>/dev/null | grep -qE "(nvenc|cuda)"; then
        echo "NVENC encoding supported"
        return 0
    else
        echo "NVENC encoding not supported"
        return 1
    fi
}

# Function to generate concat.txt from a folder
generate_concat_file() {
    folder="$1"
    output="$2"
    cd "$folder" || exit
    files=$(ls *.mp4 | sort -n)
    for file in $files; do
        echo "file '$folder/$file'" >>"$output"
    done
    echo "Generated concat.txt"
}

# Function to combine clips using concat file and scale
combine_using_concat_file() {
    concat_file="$1"
    output="$2"
    resolution="${3:-3840x2160}"  # Default resolution is 4k (16:9)
    if check_nvenc_support; then
        ffmpeg -f concat -safe 0 -i "$concat_file" -vf "scale=$resolution:force_original_aspect_ratio=decrease,pad=$resolution:(ow-iw)/2:(oh-ih)/2" -c:v h264_nvenc -preset medium -crf 23 -c:a aac -b:a 128k "$output"
    else
        ffmpeg -f concat -safe 0 -i "$concat_file" -vf "scale=$resolution:force_original_aspect_ratio=decrease,pad=$resolution:(ow-iw)/2:(oh-ih)/2" -c:v libx264 -preset medium -crf 23 -c:a aac -b:a 128k "$output"
    fi
    echo "Clips combined and scaled successfully"
}

# Function to crop a clip
crop_clip() {
    input="$1"
    output="$2"
    width="$3"
    height="$4"
    x_position="$5"
    y_position="$6"
    if check_nvenc_support; then
        ffmpeg -i "$input" -vf "crop=$width:$height:$x_position:$y_position" -c:v h264_nvenc -preset medium -crf 23 -c:a aac -b:a 128k "$output"
    else
        ffmpeg -i "$input" -vf "crop=$width:$height:$x_position:$y_position" -c:v libx264 -preset medium -crf 23 -c:a aac -b:a 128k "$output"
    fi
    echo "Clip cropped successfully"
}

# Function to trim a clip from the beginning
trim_beginning() {
    input="$1"
    output="$2"
    start_time="$3"
    if check_nvenc_support; then
        ffmpeg -i "$input" -ss "$start_time" -c:v h264_nvenc -preset medium -crf 23 -c:a aac -b:a 128k "$output"
    else
        ffmpeg -i "$input" -ss "$start_time" -c:v libx264 -preset medium -crf 23 -c:a aac -b:a 128k "$output"
    fi
    echo "Clip trimmed from beginning successfully"
}

# Function to trim a clip from the end
trim_end() {
    input="$1"
    output="$2"
    end_time="$3"
    if check_nvenc_support; then
        ffmpeg -i "$input" -to "$end_time" -c:v h264_nvenc -preset medium -crf 23 -c:a aac -b:a 128k "$output"
    else
        ffmpeg -i "$input" -to "$end_time" -c:v libx264 -preset medium -crf 23 -c:a aac -b:a 128k "$output"
    fi
    echo "Clip trimmed from end successfully"
}

# Function to scale a clip
scale_clip() {
    input="$1"
    output="$2"
    resolution="${3:-3840x2160}"  # Default resolution is 4k (16:9)
    if check_nvenc_support; then
        ffmpeg -i "$input" -vf "scale=$resolution:force_original_aspect_ratio=decrease,pad=$resolution:(ow-iw)/2:(oh-ih)/2" -c:v h264_nvenc -preset medium -crf 23 -c:a aac -b:a 128k "$output"
    else
        ffmpeg -i "$input" -vf "scale=$resolution:force_original_aspect_ratio=decrease,pad=$resolution:(ow-iw)/2:(oh-ih)/2" -c:v libx264 -preset medium -crf 23 -c:a aac -b:a 128k "$output"
    fi
    echo "Clip scaled successfully"
}

# Function to remove parts without audio from a clip
remove_silence() {
    input="$1"
    output="$2"
    ffmpeg -i "$input" -af silenceremove=1:0:-50dB -c:a copy "$output"
    echo "Silence removed successfully"
}

# Function for picture-in-picture
picture_in_picture() {
    input_main="$1"
    input_pip="$2"
    output="$3"
    x_scale="$4"
    y_scale="$5"
    x_position="$6"
    y_position="$7"
    if check_nvenc_support; then
        ffmpeg -i "$input_main" -i "$input_pip" -filter_complex "[1:v]scale=$x_scale:$y_scale [pip]; [0:v][pip]overlay=$x_position:$y_position" -c:v h264_nvenc -preset medium -crf 23 -c:a aac -b:a 128k "$output"
    else
        ffmpeg -i "$input_main" -i "$input_pip" -filter_complex "[1:v]scale=$x_scale:$y_scale [pip]; [0:v][pip]overlay=$x_position:$y_position" -c:v libx264 -preset medium -crf 23 -c:a aac -b:a 128k "$output"
    fi
    echo "Picture-in-picture applied successfully"
}

# Function for image stabilization
image_stabilization() {
    input="$1"
    output="$2"
    if check_nvenc_support; then
        ffmpeg -i "$input" -vf vidstabdetect=shakiness=10:accuracy=15:result=transform.trf -f null -
        ffmpeg -i "$input" -vf vidstabtransform=input="transform.trf" -c:v h264_nvenc -preset medium -crf 23 -c:a aac -b:a 128k "$output"
    else
        ffmpeg -i "$input" -vf vidstabdetect=shakiness=10:accuracy=15:result=transform.trf -f null -
        ffmpeg -i "$input" -vf vidstabtransform=input="transform.trf" -c:v libx264 -preset medium -crf 23 -c:a aac -b:a 128k "$output"
    fi
    echo "Image stabilization applied successfully"
}

# Function to record screen with optional webcam and microphone
record_screen() {
    output="$1"
    webcam_flag="$2"  # true or false
    microphone_flag="$3"  # true or false
    webcam_device="/dev/video0"
    microphone_device="default"
    webcam_input=""
    microphone_input=""
    if [[ "$webcam_flag" == "true" ]]; then
        webcam_input="-f v4l2 -i $webcam_device"
    fi
    if [[ "$microphone_flag" == "true" ]]; then
        microphone_input="-f alsa -i $microphone_device"
    fi
    ffmpeg -f x11grab -video_size 1920x1080 -framerate 30 -i :0.0 $webcam_input $microphone_input -c:v h264_nvenc -preset medium -crf 23 -c:a aac -b:a 128k "$output"
    echo "Screen recorded successfully"
}

# Function to display help message
display_help() {
    toilet SaMpeg
    echo "Version 2.2024b"
    echo "------------"
    echo "Usage:"
    echo "  $0 generate-concat-file <folder> <output>"
    echo "  $0 combine-using-concat-file <concat_file> <output> [resolution]"
    echo "  $0 crop <input> <output> <width> <height> <x_position> <y_position>"
    echo "  $0 trim-beginning <input> <output> <start_time>"
    echo "  $0 trim-end <input> <output> <end_time>"
    echo "  $0 scale <input> <output> [resolution]"
    echo "  $0 remove-silence <input> <output>"
    echo "  $0 picture-in-picture <input_main> <input_pip> <output> <width> <height> <x_position> <y_position>"
    echo "  $0 image-stabilization <input> <output>"
    echo "  $0 record-screen <output> <webcam_flag> <microphone_flag>"
}

# Main script

if [[ $# -lt 1 ]]; then
    display_help
    exit 1
fi

while [[ $# -gt 0 ]]; do
    option="$1"
    case $option in
    generate-concat-file)
        if [[ $# -lt 3 ]]; then
            echo "Usage: $0 generate-concat-file <folder> <output>"
            exit 1
        fi
        generate_concat_file "$2" "$3"
        ;;
    combine-using-concat-file)
        if [[ $# -lt 3 ]]; then
            echo "Usage: $0 combine-using-concat-file <concat_file> <output> [resolution]"
            exit 1
        fi
        combine_using_concat_file "$2" "$3" "$4"
        ;;
    crop)
        if [[ $# -ne 7 ]]; then
            echo "Usage: $0 crop <input> <output> <width> <height> <x_position> <y_position>"
            exit 1
        fi
        crop_clip "$2" "$3" "$4" "$5" "$6" "$7"
        ;;
    trim-beginning)
        if [[ $# -ne 4 ]]; then
            echo "Usage: $0 trim-beginning <input> <output> <start_time>"
            exit 1
        fi
        trim_beginning "$2" "$3" "$4"
        ;;
    trim-end)
        if [[ $# -ne 4 ]]; then
            echo "Usage: $0 trim-end <input> <output> <end_time>"
            exit 1
        fi
        trim_end "$2" "$3" "$4"
        ;;
    scale)
        if [[ $# -lt 3 ]]; then
            echo "Usage: $0 scale <input> <output> [resolution]"
            exit 1
        fi
        scale_clip "$2" "$3" "$4"
        ;;
    remove-silence)
        if [[ $# -ne 3 ]]; then
            echo "Usage: $0 remove-silence <input> <output>"
            exit 1
        fi
        remove_silence "$2" "$3"
        ;;
    picture-in-picture)
        if [[ $# -ne 8 ]]; then
            echo "Usage: $0 picture-in-picture <input_main> <input_pip> <output> <width> <height> <x_position> <y_position>"
            exit 1
        fi
        picture_in_picture "$2" "$3" "$4" "$5" "$6" "$7" "$8"
        ;;
    image-stabilization)
        if [[ $# -ne 3 ]]; then
            echo "Usage: $0 image-stabilization <input> <output>"
            exit 1
        fi
        image_stabilization "$2" "$3"
        ;;
    record-screen)
        if [[ $# -lt 2 ]]; then
            echo "Usage: $0 record-screen <output> <webcam_flag> <microphone_flag>"
            exit 1
        fi
        record_screen "$2" "$3" "$4"
        ;;
    help)
        display_help
        exit 0
        ;;
    *)
        echo "Invalid option: $option"
        display_help
        exit 1
        ;;
    esac
    shift
done
