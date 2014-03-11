#include <stdio.h>
/* #include <linux/prinfo.h> */
#include "prinfo.h"

/* Function : ptree
 *
 * this function allocates whole tree data to buf
 * by the size of nr, which is number of entry.
 * also, mapping each node with its parent, child, and sibling.
 * 
 */
int ptree(struct prinfo *buf, int *nr)
{
	//read_lock(&tasklist_lock);
	
	//read_unlock(&tasklist_lock);
}

/* Function : find_root
 *
 * this function finds root process from buf,
 * and returns a root process index of buf array
 *
 */
int find_root(struct prinfo *buf, int nr)
{
	int i;
	for (i = 0; i < nr && buf[i].pid != 1; i++) {}
	return i;
	/* it should be added exception routine */
}

int find_proc(struct prinfo *buf, pid_t pid, int nr)
{
	int i;
	for (i = 0; i < nr && buf[i].pid != pid; i++) {}
	return i;
}
