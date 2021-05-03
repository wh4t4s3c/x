#!/usr/bin/env python
import sys

print("Loop and print")

# Print the usage information if there aren't two arguments:
# the script name (sys.argv[0]) and the target IP (sys.argv[1])

if len(sys.argv) != 2:
    print "Usage: " + sys.argv[0] + " [target IP]"
    sys.exit(0)

header = "Target: "+sys.argv[1]+", "

# Start an infinite loop

while(True):
    try:
        # Read the user's input after displaying ">", store in cmd
        cmd=raw_input('> ')

        # Catch "CTRL+C" or "CTRL+D" as exceptions, and exit nicely
    except (EOFError,KeyboardInterrupt) as e:
        print
        sys.exit(0)

    payload = "Command: " + cmd

    # Send the packet quietly, timeout on receiver after 3 seconds
    print( header + payload)
