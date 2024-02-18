#!/bin/bash

# Function to generate concat.txt from a folder
generate_concat_file() {
    folder="$1"
    output="$2"
    cd "$folder" || exit
    files=$(ls *.mp4 *.jpg *.jpeg *.png | sort -n)
    for file in $files; do
        echo "file '$folder/$file'" >>"$output"
    done
    echo "Generated concat.txt"
}

# Function to combine clips using concat file and scale
combine_using_concat_file() {
    concat_file="$1"
    output="$2"
    ffmpeg -f concat -safe 0 -i "$concat_file" -vf "scale=3840x2160:force_original_aspect_ratio=decrease,pad=3840:2160:(ow-iw)/2:(oh-ih)/2" -c:v libx264 -preset medium -crf 23 -c:a aac -b:a 128k "$output"
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
    ffmpeg -i "$input" -vf "crop=$width:$height:$x_position:$y_position" "$output"
    echo "Clip cropped successfully"
}

# Function to trim a clip from the beginning
trim_beginning() {
    input="$1"
    output="$2"
    start_time="$3"
    ffmpeg -i "$input" -ss "$start_time" -c copy "$output"
    echo "Clip trimmed from beginning successfully"
}

# Function to trim a clip from the end
trim_end() {
    input="$1"
    output="$2"
    end_time="$3"
    ffmpeg -i "$input" -to "$end_time" -c copy "$output"
    echo "Clip trimmed from end successfully"
}

# Function to scale a clip
scale_clip() {
    input="$1"
    output="$2"
    ffmpeg -i "$input" -vf "scale=3840x2160:force_original_aspect_ratio=decrease,pad=3840:2160:(ow-iw)/2:(oh-ih)/2" "$output"
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
    echo "The video fusing interface."
    echo "Powered by FFmpeg."
    echo "Version 2.2024-a"
    echo "------------"
    echo "Usage:"
    echo "  $0 generate-concat-file <folder> <output>"
    echo "  $0 combine-using-concat-file <concat_file> <output>"
    echo "  $0 crop <input> <output> <width> <height> <x_position> <y_position>"
    echo "  $0 trim-beginning <input> <output> <start_time>"
    echo "  $0 trim-end <input> <output> <end_time>"
    echo "  $0 scale <input> <output>"
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
            echo "Usage: $0 combine-using-concat-file <concat_file> <output>"
            exit 1
        fi
        combine_using_concat_file "$2" "$3"
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
        if [[ $# -ne 3 ]]; then
            echo "Usage: $0 scale <input> <output>"
            exit 1
        fi
        scale_clip "$2" "$3"
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

