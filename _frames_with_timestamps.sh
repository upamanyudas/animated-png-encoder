# Regular expression definitions to get frame number, and to get video duration from ffmpeg -i
FRAME_REGEX="frame-([0-9]*)\.png"
LEN_REGEX="Duration: ([0-9]*):([0-9]*):([0-9]*)\.([0-9]*), start"

# Loops through the files passed in command line arguments,
# example: videotoframes video-*.mp4
#      or: videotoframes file1.mp4 file2.mp4 file3.mp4
for vf in "$@"; do
    video_info=$(ffmpeg -i $vf 2>&1)                                                                                                                        # Get the video info as a string from ffmpeg -i
    [[ $video_info =~ $LEN_REGEX ]]                                                                                                                         # Extract length using reges; Groups 1=hr; 2=min; 3=sec; 4=sec(decimal fraction)
    LENGTH_MS=$(bc <<< "scale=2; ${BASH_REMATCH[1]} * 3600000 + ${BASH_REMATCH[2]} * 60000 + ${BASH_REMATCH[3]} * 1000 + ${BASH_REMATCH[4]} * 10")          # Calculate length of video in MS from above regex extraction

    filename=$(echo $vf | cut -d"." -f1)

    mkdir $filename                                                # Make a directory for the frames (same as the video file prefixed with ""
    ffmpeg -i $vf -filter:v scale=-1:820 -r 30 -f image2 $filename/frame-%05d.png         # Convert the video file to frames using ffmpeg, -r = 30 fps
    FRAMES=$(ls -1 $filename | wc -l)                              # Get the total number of frames produced by the video (used to extrapolate the timestamp of the frame in a few lines)

    # Loop through the frames, generate a timestamp in milliseconds, and rename the files
    for f in $filename/frame-*; do
        [[ $f =~ $FRAME_REGEX ]]                                                        # Regex to grab the frame number for each file
        timestamp=$(bc <<< "scale=0; $LENGTH_MS/$FRAMES*${BASH_REMATCH[1]}")            # Calculate the timestamp (length_of_video / total_frames_generated * files_frame_number)
        `printf "mv $f $filename/screen_%07d-%s" $timestamp $(basename $f)`             # Execute a mv (move) command, uses the `printf ...` (execute command returned by printf) syntax to zero-pad the timestamp in the file name
    done;

    #Rename files
    for x in $filename/screen_*.png ; do
      mv -i "$x" "${x%-f*.png}.png"
    done;
done;
