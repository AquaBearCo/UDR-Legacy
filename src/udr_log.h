// =====================================================
// udr_log.h — UDR Logging Interface
// =====================================================
// Provides lightweight logging macros and helpers for
// debug, info, warning, and error output.
// =====================================================

#ifndef UDR_LOG_H
#define UDR_LOG_H

#include <cstdio>
#include <cstdarg>
#include <ctime>

// =====================================================
// 10. Log levels
// =====================================================
enum UDRLogLevel {
    LOG_DEBUG = 0,
    LOG_INFO,
    LOG_WARN,
    LOG_ERROR
};

// =====================================================
// 20. Global configuration
// =====================================================
extern int UDR_LOG_LEVEL;  // defined in udr_log.cpp

// =====================================================
// 30. Core logger function
// =====================================================
inline void udr_log(UDRLogLevel level, const char* fmt, ...) {
    if (level < UDR_LOG_LEVEL)
        return;

    const char* prefix;
    switch (level) {
        case LOG_DEBUG: prefix = "[debug]"; break;
        case LOG_INFO:  prefix = "[info] "; break;
        case LOG_WARN:  prefix = "[warn] "; break;
        case LOG_ERROR: prefix = "[error]"; break;
        default:        prefix = "[log]  "; break;
    }

    std::time_t now = std::time(nullptr);
    char tbuf[32];
    std::strftime(tbuf, sizeof(tbuf), "%Y-%m-%d %H:%M:%S", std::localtime(&now));

    std::fprintf(stderr, "%s %s ", tbuf, prefix);

    va_list args;
    va_start(args, fmt);
    std::vfprintf(stderr, fmt, args);
    va_end(args);

    std::fprintf(stderr, "\n");
}

// =====================================================
// 40. Convenience macros
// =====================================================
#define LOGD(...) udr_log(LOG_DEBUG, __VA_ARGS__)
#define LOGI(...) udr_log(LOG_INFO,  __VA_ARGS__)
#define LOGW(...) udr_log(LOG_WARN,  __VA_ARGS__)
#define LOGE(...) udr_log(LOG_ERROR, __VA_ARGS__)

#endif // UDR_LOG_H
