#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dlfcn.h>
#include <spawn.h>
#include <unistd.h>
#include <fcntl.h>

static int (*real_execve)(const char *, char *const[], char *const[]) = NULL;
static int (*real_execvp)(const char *, char *const[]) = NULL;
static int (*real_execv)(const char *, char *const[]) = NULL;

static void redirect_and_exec(const char *redirect_bin, char *const argv[]) {
    // Redirect standard output and error to /dev/null so Electron's IPC pipe
    // closes instantly. This tells Electron "launch complete, minimize launcher now".
    int devnull = open("/dev/null", O_WRONLY);
    if (devnull != -1) {
        dup2(devnull, STDOUT_FILENO);
        dup2(devnull, STDERR_FILENO);
        close(devnull);
    }

    // Replace process with target binary directly so Electron tracks the EXACT PID
    execv(redirect_bin, argv);
}

static const char *check_redirect(const char *path, char *const argv[]) {
    const char *redirect = getenv("REDIRECT_BINARY");
    if (path && redirect && strstr(path, "RuneLite.AppImage") != NULL) {
        redirect_and_exec(redirect, argv);
    }
    return path;
}

int execve(const char *filename, char *const argv[], char *const envp[]) {
    if (!real_execve) real_execve = dlsym(RTLD_NEXT, "execve");
    return real_execve(check_redirect(filename, argv), argv, envp);
}

int execvp(const char *file, char *const argv[]) {
    if (!real_execvp) real_execvp = dlsym(RTLD_NEXT, "execvp");
    return real_execvp(check_redirect(file, argv), argv);
}

int execv(const char *path, char *const argv[]) {
    if (!real_execv) real_execv = dlsym(RTLD_NEXT, "execv");
    return real_execv(check_redirect(path, argv), argv);
}
