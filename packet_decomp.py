import serial
from enum import Enum
import numpy as np
import cv2
import sys
import time

####################
# 
# |  ID  | Ycoord | Xcoord |   Misc   |  Value  |  Amount  |
# 
# |   Misc   | = |    RLE MSBs    | Channel Type | Ycoord LSB | Xcoord LSB | 
#    8 bits            4 bits          2 bits        1 bit         1 bit  
#
# 1) Read the ID of the packet. 
#   - If it is not prev_id + 1, keep reading until it is prev_id + 2.
# 2) Read the first frame of the Y coordinate of the pixel.
# 3) Read the first frame of the X coordinate of the pixel.
# 4) Read the Misc value and decompose it into miscellaneous info.
# 5) Read the value of the pixel.
# 6) Read the amount of pixels to be filled with the value.
####################


class PackFrame(Enum) :
    ID = 0
    YCOORD = 1
    XCOORD = 2
    MISC = 3
    VALUE = 4
    AMOUNT = 5

PACKET_LEN = 6
FRAME_WIDTH = 512
FRAME_HEIGHT = 384

curr_video_frame = {
    0 : np.zeros((FRAME_HEIGHT, FRAME_WIDTH), dtype=np.uint8), # Y
    1 : np.zeros((FRAME_HEIGHT//2, FRAME_WIDTH), dtype=np.uint8), # U
    2 : np.zeros((FRAME_HEIGHT//2, FRAME_WIDTH), dtype=np.uint8)  # V
}

next_video_frame = {
    0 : np.zeros((FRAME_HEIGHT, FRAME_WIDTH), dtype=np.uint8), # Y
    1 : np.zeros((FRAME_HEIGHT//2, FRAME_WIDTH), dtype=np.uint8), # U
    2 : np.zeros((FRAME_HEIGHT//2, FRAME_WIDTH), dtype=np.uint8)  # V
}

curr_id = -1
curr_frame_idx = 0
tracing = False
frames_lost_count = 0

frame_counter = 0
packets_received = 0

y_coord_msb = 0
x_coord_msb = 0
misc = 0
value = 0
amount_lsb = 0
amount_msbs = 0

def redraw() :
    global curr_id, tracing, frame_counter
    global curr_video_frame, next_video_frame
    global curr_frame_idx

    c_time = time.localtime(time.time())
    print(f"--- Frame # {frame_counter} : {c_time.tm_hour}:{c_time.tm_min}:{c_time.tm_sec} ---", file=sys.stderr)
    u_resized = cv2.resize(next_video_frame[1], (FRAME_WIDTH, FRAME_HEIGHT), interpolation=cv2.INTER_NEAREST)
    v_resized = cv2.resize(next_video_frame[2], (FRAME_WIDTH, FRAME_HEIGHT), interpolation=cv2.INTER_NEAREST)
    yuv = cv2.merge((next_video_frame[0], u_resized, v_resized))
    video_frame = cv2.cvtColor(yuv.astype(np.uint8), cv2.COLOR_YUV2BGR)
    cv2.imshow("OV7670", video_frame)
    curr_video_frame = {k : next_video_frame[k] for k in next_video_frame}
    curr_id = -1 # First ID is zero
    tracing = False
    curr_frame_idx = 0
    frame_counter += 1


def match_frame(data : int) :
    global curr_id, curr_frame_idx, tracing, frames_lost_count, packets_received
    global y_coord_msb, x_coord_msb, misc, value, amount_lsb, amount_msbs
    global next_video_frame
    
    if tracing:
        if curr_frame_idx == PackFrame.ID.value:
            if data == 255:
                print(f"TRACE: Stopped tracing - Found Frame End marker (ID 255).", file=sys.stderr)
                redraw()
                return
            expected_id = (curr_id + 1) % 255
            if data == expected_id:
                print(f"TRACE: Stopped tracing - Found expected ID {expected_id}. Lost {frames_lost_count} packets.", file=sys.stderr)
                tracing = False
                curr_id = data
                curr_frame_idx = 1
                return
            else:
                frames_lost_count += 1
                print(f"TRACE: Discarding byte {curr_frame_idx} - {data:02x}. Waiting for ID {expected_id} or 255.", file=sys.stderr) # Too verbose during normal tracing
                return
        else:
            curr_frame_idx = (curr_frame_idx + 1) % PACKET_LEN
            return 

    match curr_frame_idx :
        case PackFrame.ID.value :
            packet_id = data
            if packet_id == 255 :
                print(f"INFO: Received Frame End marker (ID 255) after packet ID {curr_id}.", file=sys.stderr)
                redraw()
                return
            expected_id = (curr_id + 1) % 255
            if packet_id != expected_id:
                print(f"ERROR: Transmission error: Expected ID {expected_id}, got {packet_id}. Starting trace.", file=sys.stderr)
                tracing = True
                return
            # The ID is correct and not 255
            curr_id = packet_id
            # print(f"INFO: Received packet ID {packet_id}", file=sys.stderr)
            curr_frame_idx += 1

        case PackFrame.YCOORD.value :
            y_coord_msb = data
            curr_frame_idx += 1

        case PackFrame.XCOORD.value :
            x_coord_msb = data
            curr_frame_idx += 1

        case PackFrame.MISC.value :
            misc = data
            amount_msbs = (misc & 0b00001111)
            curr_frame_idx += 1

        case PackFrame.VALUE.value :
            value = data
            curr_frame_idx += 1

        case PackFrame.AMOUNT.value :
            amount_lsb = data
            y_lsb = (misc >> 6) & 0b1
            x_lsb = (misc >> 7) & 0b1
            ch_type = (misc >> 4) & 0b11
            amount = (amount_msbs << 8) | amount_lsb
            y_coord = (y_coord_msb << 1) | y_lsb
            x_coord = (x_coord_msb << 1) | x_lsb

            print(f"DEBUG: Packet ID {curr_id} received. Parsed: ch={ch_type}, y={y_coord}, x={x_coord}, amount={amount}, value={value}", file=sys.stderr)
            # print(f"DEBUG: Packet ID {curr_id} received. Parsed: ch={ch_type}, y={y_coord}, x={x_coord}, amount={amount}, value={value}")

            is_valid = True
            if ch_type not in next_video_frame:
                 is_valid = False
            if is_valid:
                try:
                    next_video_frame[ch_type][y_coord][x_coord : x_coord + amount] = value
                    packets_received += 1
                    # print(f"INFO: Applied packet ID {curr_id}: ch={ch_type}, y={y_coord}, x={x_coord}, amount={amount}, value={value}", file=sys.stderr)
                except IndexError as e:
                    print(f"CRITICAL: IndexError applying packet ID {curr_id}: ch={ch_type}, y={y_coord}, x={x_coord}, amount={amount}, value={value}", file=sys.stderr)
                    print(f"CRITICAL: Channel {ch_type} dimensions: {next_video_frame[ch_type].shape}", file=sys.stderr)
                    print(f"CRITICAL: Slice attempted: [{y_coord}][{x_coord}:{x_coord+amount}]", file=sys.stderr)
                    print(f"CRITICAL: Entering trace due to IndexError.", file=sys.stderr)
                    tracing = True
            else:
                 tracing = True

            curr_frame_idx = 0

        case _ :
            print(f"ERROR: Incorrect frame index : {curr_frame_idx}. Resetting.", file=sys.stderr)
            curr_frame_idx = 0


cv2.namedWindow("OV7670", cv2.WINDOW_NORMAL, )
cv2.resizeWindow("OV7670", FRAME_WIDTH, FRAME_HEIGHT)

try:
    with serial.Serial(port="COM4", baudrate=921600, bytesize=serial.EIGHTBITS, parity=serial.PARITY_NONE, timeout=0) as receiver :
        
        print("INFO: Starting receiver on COM4 at 921600 baud...", file=sys.stderr)
        redraw()
        receiver.set_buffer_size(65536)
        receiver.read_all()
        while True :
            frame = receiver.read(1)
            if len(frame) == 0 :
                if cv2.waitKey(1) == 27: # ESC
                    break
                continue
            match_frame(frame[0])
            if cv2.waitKey(1) == 27: # ESC
                break

except serial.SerialException as e:
    print(f"CRITICAL: Serial port error: {e}", file=sys.stderr)
except Exception as e:
    print(f"CRITICAL: An unexpected error occurred: {e}", file=sys.stderr)
    import traceback
    traceback.print_exc()


cv2.destroyAllWindows()
print(f"INFO: Total packets received : {packets_received}")
print(f"INFO: Frames lost : {frames_lost_count}")