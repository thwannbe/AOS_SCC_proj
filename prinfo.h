/*This header file is used for providing process information,
 * also defines ptree function.
 * Note that you should declare ptree func in your main code.
 *
 * Last edited 2014.03.10 - osw
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <linux/types.h>
#include <linux/sched.h>

struct prinfo {
	char comm[64];			/* name of program executed */
	pid_t pid;				/* process id */
	long state;				/* current state of process */
	pid_t parent_pid;		/* process id of parent */
	pid_t first_child_pid;	/* pid of youngest child */
	pid_t next_sibling_pid;	/* pid of older sibling */
	long uid;				/* user id of process owner */
};

int ptree(struct prinfo *buf, int *nr);
int find_root(struct prinfo *buf, int nr);
int find_proc(struct prinfo *buf, pid_t pid, int nr);
