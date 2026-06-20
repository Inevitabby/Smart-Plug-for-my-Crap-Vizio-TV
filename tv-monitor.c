#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include "config.h"

#define PORT 47303
#define BUFFER_SIZE 4096
#define PLUG_PORT 80

const char *http_ok = "HTTP/1.1 200 OK\r\nContent-Length: 0\r\nConnection: close\r\n\r\n";

static void run_kscreen(const char *arg) {
    pid_t pid = fork();
    if (pid == 0) {
        setsid();
        char *args[] = {"kscreen-doctor", (char *)arg, NULL};
        execvp("kscreen-doctor", args);
        _exit(1);
    }
}

static int query_plug() {
    int fd;
    struct sockaddr_in addr;
    char buf[BUFFER_SIZE];

    if ((fd = socket(AF_INET, SOCK_STREAM, 0)) < 0) return -1;

    addr.sin_family = AF_INET;
    addr.sin_port = htons(PLUG_PORT);
    if (inet_pton(AF_INET, PLUG_IP, &addr.sin_addr) <= 0) { close(fd); return -1; }

    if (connect(fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) { close(fd); return -1; }

    const char *req =
        "GET /binary_sensor/Device%20In%20Use HTTP/1.1\r\n"
        "Host: " PLUG_IP "\r\n"
        "Connection: close\r\n\r\n";

    send(fd, req, strlen(req), 0);

    ssize_t n = read(fd, buf, BUFFER_SIZE - 1);
    close(fd);

    if (n <= 0) return -1;
    buf[n] = '\0';

    if (strstr(buf, "\"ON\"")) return 1;
    if (strstr(buf, "\"OFF\"")) return 0;
    return -1;
}

int main() {
    int server_fd, client_fd;
    struct sockaddr_in address;
    int opt = 1;
    socklen_t addrlen = sizeof(address);
    char buffer[BUFFER_SIZE];

    // Query plug state on startup
    int state = query_plug();
    if (state == 1)
        run_kscreen("output.HDMI-A-4.enable");
    else if (state == 0)
        run_kscreen("output.HDMI-A-4.disable");
    // if -1 (error/unreachable), do nothing and let events drive state

    if ((server_fd = socket(AF_INET, SOCK_STREAM, 0)) < 0) return 1;
    if (setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt)) < 0) return 1;

    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY;
    address.sin_port = htons(PORT);

    if (bind(server_fd, (struct sockaddr *)&address, sizeof(address)) < 0) return 1;
    if (listen(server_fd, 3) < 0) return 1;

    while (1) {
        if ((client_fd = accept(server_fd, (struct sockaddr *)&address, &addrlen)) < 0) continue;

        ssize_t n = read(client_fd, buffer, BUFFER_SIZE - 1);
        if (n > 0) {
            buffer[n] = '\0';

            char *end = strstr(buffer, "\r\n");
            if (end) *end = '\0';

            send(client_fd, http_ok, strlen(http_ok), 0);
            close(client_fd);

            if (strstr(buffer, "POST /tv_on"))
                run_kscreen("output.HDMI-A-4.enable");
            else if (strstr(buffer, "POST /tv_off"))
                run_kscreen("output.HDMI-A-4.disable");
        } else {
            close(client_fd);
        }
    }
    return 0;
}
