/* this file is part of srm http://srm.sourceforge.net/
   It is licensed under the MIT/X11 license */

#include "config.h"

#include <errno.h>
#include <fcntl.h>
#include <getopt.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>

#include "srm.h"

/* global variables used in other files */
int options = 0;
char *program_name;

/* variables used by getopt() */
static int show_help = 0;
static int show_version = 0;

static struct option longopts[] = {
  { "directory", no_argument, NULL, 'd' },
  { "force", no_argument, NULL, 'f' },
  { "interactive", no_argument, NULL, 'i' },
  { "recursive", no_argument, NULL, 'r' },
  { "simple", no_argument, NULL, 's'},
  { "openbsd", no_argument, NULL, 'P'},
  { "dod", no_argument, NULL, 'D'},
  { "doe", no_argument, NULL, 'E'},
  { "verbose", no_argument, NULL, 'v' },
  { "help", no_argument, &show_help, 'h' },
  { "version", no_argument, &show_version, 'V' },
  { NULL, no_argument, NULL, 0 }
};

int main(int argc, char *argv[]) {
  int opt=0, i=0, q=0;
  char* *trees=0;

  if ( (program_name = strrchr(argv[0], DIRSEP)) != NULL)
    program_name++;
  else
    program_name = argv[0];

  while ((opt = getopt_long(argc, argv, "dDEfhirRPsvV", longopts, NULL)) != -1)
    switch (opt) {
    case ':': 
    case '?': 
      /* getopt() prints an error message for these cases */
      fprintf(stderr, "Try `%s --help' for more information.\n", program_name);
      exit(EXIT_FAILURE);
    case 0: break; 
    case 'd': break;
    case 'h': show_help=1; break;
    case 'f': 
      options |= OPT_F;
      break;
    case 'i':
      options |= OPT_I;
      break;
    case 'r':
    case 'R':
      options |= OPT_R;
      break;
    case 's':
      options |= SUNLINK_MODE_SIMPLE;
      break;
    case 'P':
      options |= SUNLINK_MODE_OPENBSD;
      break;
    case 'D':
      options |= SUNLINK_MODE_DOD;
      break;
    case 'E':
      options |= SUNLINK_MODE_DOE;
      break;
    case 'v':
      options |= OPT_V;
      break;
    case 'V': show_version=1; break;
    default:
      error("unhandled option %c", opt);
    }

  if (show_help) {
    printf(
	   "Usage: %s [OPTION]... [FILE]...\n"
	   "Overwrite and remove (unlink) the files.\n"
	   "\n"
	   "  -d, --directory     ignored (for compatability with rm(1))\n"
	   "  -f, --force         ignore nonexistant files, never prompt\n"
	   "  -i, --interactive   prompt before any removal\n"
           "  -s, --simple        overwrite with single pass using 0x00\n"
           "  -P, --openbsd       overwrite with three passes like OpenBSD rm\n"
           "  -D, --dod           overwrite with 7 US DoD compliant passes\n"
           "  -E, --doe           overwrite with 3 US DoE compliant passes\n"
	   "  -r, -R, --recursive remove the contents of directories\n"
	   "  -v, --verbose       explain what is being done\n"
	   "  -h, --help          display this help and exit\n"
	   "  -V, --version       display version information and exit\n",
	   program_name);
    exit(EXIT_SUCCESS);
  }

  if (show_version) {
    printf("%s (" PACKAGE ") " VERSION "\n", program_name);
    exit(EXIT_SUCCESS);
  }

  if (optind == argc) {
    printf("%s: too few arguments\n", program_name);
    printf("Try `%s --help' for more information.\n", program_name);
    exit(EXIT_FAILURE);
  }

  init_random(getpid()^time(NULL));

  trees=alloca((argc-optind+1) * sizeof(char*));
  if(!trees)
  {
    perror("could not allocate memory");
    exit(EXIT_FAILURE);
  }
  for (i = optind, q = 0; i < argc; i++, q++) 
    trees[q] = argv[i];
  trees[q] = NULL;

  exit(tree_walker(trees));
}
