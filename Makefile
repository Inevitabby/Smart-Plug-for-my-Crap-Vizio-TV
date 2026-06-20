CC = gcc
CFLAGS = -O2 -Wall -Wextra

TARGET = tv-monitor
SRC = tv-monitor.c
ESPHOME_BIN = .esphome/build/vizio/.pioenvs/vizio/firmware.ota.bin

all: $(TARGET) firmware.ota.bin.gz

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -o $(TARGET) $(SRC)

firmware.ota.bin.gz: vizio.yaml
	esphome compile vizio.yaml
	gzip -kf $(ESPHOME_BIN)
	cp $(ESPHOME_BIN).gz firmware.ota.bin.gz

clean:
	rm -f $(TARGET) firmware.ota.bin.gz
