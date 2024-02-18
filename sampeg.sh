#!/bin/bash

# Function to check if NVENC is supported
check_nvenc_support() {
    if ffmpeg -hide_banner -encoders | grep -q "h264_nvenc"; then
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

# Function to display help message
display_help() {
    toilet SaMpeg
    echo "Version 1.0"
    echo "------------"
    echo "Usage:"
    echo "  $0 generate-concat-file <folder> <output>"
    echo "  $0 combine-using-concat-file <concat_file> <output> [resolution]"
    echo "  $0 crop <input> <output> <width> <height> <x_position> <y_position>"
    echo "  $0 trim-beginning <input> <output> <start_time>"
    echo "  $0 trim-end <input> <output> <end_time>"
    echo "  $0 scale <input> <output> [resolution]"
    echo "  $0 remove-silence <input> <output>"
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
