
import serial
from enum import Enum
import numpy as np
import cv2


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

curr_frame = {
    0 : np.zeros((FRAME_HEIGHT, FRAME_WIDTH)),
    1 : np.zeros((FRAME_HEIGHT//2, FRAME_WIDTH)),
    2 : np.zeros((FRAME_HEIGHT//2, FRAME_WIDTH))
}

next_frame = {
    0 : np.zeros((FRAME_HEIGHT, FRAME_WIDTH)),
    1 : np.zeros((FRAME_HEIGHT//2, FRAME_WIDTH)),
    2 : np.zeros((FRAME_HEIGHT//2, FRAME_WIDTH))
}

curr_packet_id = -1
curr_frame_idx = 0

y_coord = 0
x_coord = 0
ch_type = 0
value   = 0
amount  = 0

def match_frame(data : int) :
    global curr_packet_id, curr_frame_idx, y_coord, x_coord, ch_type, value, amount
    match curr_frame_idx :
        case PackFrame.ID.value :
            if data == 255:
                curr_packet_id = 255
            elif data != curr_packet_id + 1:
                print(f"Transmission error - a packet with id {data} when current id is {curr_packet_id}")
                exit(0)
            else :
                curr_packet_id = data % 254
        case PackFrame.YCOORD.value :
            y_coord = data << 1
        case PackFrame.XCOORD.value :
            x_coord = data << 1
        case PackFrame.MISC.value :
            amount = int(data & 0b1111) << 8
            ch_type = (data >> 4) & 0b11
            y_coord |= (data >> 6) & 0b1
            x_coord |= (data >> 7) & 0b1
        case PackFrame.VALUE.value :
            value = data
        case PackFrame.AMOUNT.value :
            amount += data
        case _ :
            print("Invalid packet index")
            exit(1)
    curr_frame_idx += 1

frame_counter = 0

# NEED TO APPLY CHANGE ONLY WHEN THE NEXT ID IS CORRECT
# AND FUCKING SIMULATE ALL THROUGH
# DONT RELY ON THE NEW UARTS - YOURE FUCKED
# THINK ABOUT THE PRESENTATION OF RESULTS
# IT'S DOABLE - JUST GET AN IDEA
with serial.Serial("COM4", 57600, 8, "N") as receiver :
    while True :
        frame = receiver.read(1)
        if len(frame) == 0 :
            continue
        print(f"{curr_frame_idx} - {frame.hex()}")
        match_frame(frame[0])
        if curr_packet_id == 255:
            curr_frame = next_frame
            curr_frame_idx = 1 # DONT FORGET TO CHANGE TO 0!!!!
            curr_packet_id = -1
            print(f"FRAME # {frame_counter}")
            frame_counter += 1
        elif curr_frame_idx == PACKET_LEN: # read the packet, start redrawing
            next_frame[ch_type][y_coord][x_coord:x_coord + amount] = value
            curr_frame_idx = 0
        y = curr_frame[0]
        u = cv2.resize(curr_frame[1], (FRAME_WIDTH, FRAME_HEIGHT), interpolation=cv2.INTER_LINEAR)
        v = cv2.resize(curr_frame[2], (FRAME_WIDTH, FRAME_HEIGHT), interpolation=cv2.INTER_LINEAR)
        yuv = cv2.merge((y, u, v))
        bgr = cv2.cvtColor(yuv.astype(np.uint8), cv2.COLOR_YUV2BGR)
        cv2.imshow("OV7670", bgr)
        if cv2.waitKey(1) == 27: # ESC
            break
        
