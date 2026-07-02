#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#ifdef _WIN32
#include <process.h>
#include <windows.h>
#else
#include <errno.h>
#include <limits.h>
#include <unistd.h>
#ifdef __APPLE__
#include <mach-o/dyld.h>
#endif
#endif

#ifndef PATH_MAX
#define PATH_MAX 4096
#endif

static bool
starts_with (const char *s, const char *prefix)
{
  return strncmp (s, prefix, strlen (prefix)) == 0;
}

static bool
ends_with (const char *s, const char *suffix)
{
  size_t slen = strlen (s);
  size_t tlen = strlen (suffix);
  return slen >= tlen && strcmp (s + slen - tlen, suffix) == 0;
}

static char *
xstrdup (const char *s)
{
  char *out = (char *) malloc (strlen (s) + 1);
  if (out == NULL)
    {
      perror ("malloc");
      exit (127);
    }
  strcpy (out, s);
  return out;
}

static char *
xstrndup_local (const char *s, size_t len)
{
  char *out = (char *) malloc (len + 1);
  if (out == NULL)
    {
      perror ("malloc");
      exit (127);
    }
  memcpy (out, s, len);
  out[len] = '\0';
  return out;
}

static char *
strip_trailing_xw (const char *arch)
{
  size_t len = strlen (arch);
  if (len > 3 && ends_with (arch, "_xw"))
    return xstrndup_local (arch, len - 3);
  if (len > 2 && ends_with (arch, "xw"))
    return xstrndup_local (arch, len - 2);
  return NULL;
}

static char *
join_arch_arg (const char *prefix, const char *arch)
{
  size_t len = strlen (prefix) + strlen (arch) + 1;
  char *out = (char *) malloc (len);
  if (out == NULL)
    {
      perror ("malloc");
      exit (127);
    }
  snprintf (out, len, "%s%s", prefix, arch);
  return out;
}

static char *
make_wa_march (const char *arch)
{
  return join_arch_arg ("-Wa,-march=", arch);
}

static void
remember_xw_arch (char **slot, const char *arch)
{
  if (*slot != NULL)
    free (*slot);
  *slot = xstrdup (arch);
}

static bool
is_print_only_arg (const char *arg)
{
  return starts_with (arg, "-print-") || starts_with (arg, "--print-");
}

static char *
get_self_path (void)
{
  char buffer[PATH_MAX];
#ifdef _WIN32
  DWORD len = GetModuleFileNameA (NULL, buffer, sizeof (buffer));
  if (len == 0 || len >= sizeof (buffer))
    {
      fprintf (stderr, "xw gcc wrapper: GetModuleFileNameA failed\n");
      exit (127);
    }
  return xstrdup (buffer);
#elif defined(__APPLE__)
  uint32_t size = sizeof (buffer);
  if (_NSGetExecutablePath (buffer, &size) != 0)
    {
      fprintf (stderr, "xw gcc wrapper: executable path is too long\n");
      exit (127);
    }
  return xstrdup (buffer);
#else
  ssize_t len = readlink ("/proc/self/exe", buffer, sizeof (buffer) - 1);
  if (len < 0)
    {
      perror ("readlink");
      exit (127);
    }
  buffer[len] = '\0';
  return xstrdup (buffer);
#endif
}

static char *
make_real_path (const char *self)
{
#ifdef _WIN32
  size_t len = strlen (self);
  if (len >= 4 && (_stricmp (self + len - 4, ".exe") == 0))
    {
      char *out = xstrndup_local (self, len - 4);
      char *with_suffix = join_arch_arg (out, ".real.exe");
      free (out);
      return with_suffix;
    }
  return join_arch_arg (self, ".real.exe");
#else
  return join_arch_arg (self, ".real");
#endif
}

int
main (int argc, char **argv)
{
  char *self = get_self_path ();
  char *real = make_real_path (self);
  char *xw_arch = NULL;
  bool print_only = false;
  char **new_argv = (char **) calloc ((size_t) argc + 3, sizeof (char *));
  int out = 0;

  if (new_argv == NULL)
    {
      perror ("calloc");
      return 127;
    }

  new_argv[out++] = real;
  for (int i = 1; i < argc; ++i)
    {
      const char *arg = argv[i];
      char *stripped = NULL;

      if (is_print_only_arg (arg))
        print_only = true;

      if ((strcmp (arg, "-march") == 0 || strcmp (arg, "--march") == 0)
          && i + 1 < argc)
        {
          new_argv[out++] = argv[i];
          stripped = strip_trailing_xw (argv[i + 1]);
          if (stripped != NULL)
            {
              remember_xw_arch (&xw_arch, argv[i + 1]);
              new_argv[out++] = stripped;
            }
          else
            new_argv[out++] = argv[i + 1];
          ++i;
          continue;
        }

      if (starts_with (arg, "-march="))
        {
          stripped = strip_trailing_xw (arg + 7);
          if (stripped != NULL)
            {
              remember_xw_arch (&xw_arch, arg + 7);
              new_argv[out++] = join_arch_arg ("-march=", stripped);
              free (stripped);
              continue;
            }
        }
      else if (starts_with (arg, "--march="))
        {
          stripped = strip_trailing_xw (arg + 8);
          if (stripped != NULL)
            {
              remember_xw_arch (&xw_arch, arg + 8);
              new_argv[out++] = join_arch_arg ("--march=", stripped);
              free (stripped);
              continue;
            }
        }

      new_argv[out++] = argv[i];
    }

  if (xw_arch != NULL && !print_only)
    new_argv[out++] = make_wa_march (xw_arch);
  new_argv[out] = NULL;

#ifdef _WIN32
  intptr_t rc = _spawnv (_P_WAIT, real, (const char * const *) new_argv);
  if (rc == -1)
    {
      perror (real);
      return 127;
    }
  return (int) rc;
#else
  execv (real, new_argv);
  perror (real);
  return 127;
#endif
}
