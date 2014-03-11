#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "prinfo.h" /* temporary path */
#include <linux/types.h>
/* #include <linux/prinfo.h> */

int now_depth = 0;/* how deep present proc in recursive loop */
struct prinfo *proc_list;/* process list */
int num_proc;/* number of entry in process list */

int ptree(struct prinfo *buf, int *nr);
int find_root(struct prinfo *buf, int nr);
int find_proc(struct prinfo *buf, pid_t pid, int nr);

/*
 * Function : print_line
 * 
 * this function just receives struct data and depth from buf
 * as parameters, and print only one line with appropriate tabs.
 *
 */
void print_line(struct prinfo p, int depth)
{
	int i;
	for (i = 0; i < depth; i++){
		printf("\t");
	}
	printf("%s,%d,%ld,%d,%d,%d,%ld\n",p.comm,p.pid,p.state,p.parent_pid,p.first_child_pid,p.next_sibling_pid,p.uid);
}

/*
 * Function : print_tree
 *
 * this function receives root node from buf as parameters,
 * and print whole tree with recursive loop.
 *
 */
void print_tree(struct prinfo root)
{
	struct prinfo n_root;/* next recursive loop proc node */
	print_line(root, now_depth);
	now_depth++;
	if (root.first_child_pid != 0) {
		n_root = proc_list[find_proc(proc_list, root.first_child_pid,num_proc)];
		print_tree(n_root);
	}
	now_depth--;
	if (root.next_sibling_pid != 0) {
		n_root = proc_list[find_proc(proc_list, root.next_sibling_pid, num_proc)];
		print_tree(n_root);
	}
}
	
int main(int argc, const char *argv[])
{
	/* for real
	ptree(proc_list,&num_proc);
	print_tree(find_root(proc_list,num_proc);
	*/
	/* for test */
	proc_list = malloc(5*sizeof(struct prinfo));
	num_proc = 5; /* comm pid state parent_pid, f_ch_id, n_si_id, uid */
	memcpy(proc_list[0].comm,"root",64);
	proc_list[0].pid = 1;
	proc_list[0].state = 1;
	proc_list[0].parent_pid = 0;
	proc_list[0].first_child_pid = 2;
	proc_list[0].next_sibling_pid = 0;
	proc_list[0].uid = 1;
	memcpy(proc_list[1].comm,"ch1",64);
	proc_list[1].pid = 2;
	proc_list[1].state = 1;
	proc_list[1].parent_pid = 1;
	proc_list[1].first_child_pid = 4;
	proc_list[1].next_sibling_pid = 3;
	proc_list[1].uid = 2;
	memcpy(proc_list[2].comm,"ch2",64);
	proc_list[2].pid = 3;
	proc_list[2].state = 1;
	proc_list[2].parent_pid = 1;
	proc_list[2].first_child_pid = 0;
	proc_list[2].next_sibling_pid = 0;
	proc_list[2].uid = 3;
	memcpy(proc_list[3].comm,"ch1-1",64);
	proc_list[3].pid = 4;
	proc_list[3].state = 1;
	proc_list[3].parent_pid = 2;
	proc_list[3].first_child_pid = 0;
	proc_list[3].next_sibling_pid = 5;
	proc_list[3].uid = 4;
	memcpy(proc_list[4].comm,"ch1-2",64);
	proc_list[4].pid = 5;
	proc_list[4].state = 1;
	proc_list[4].parent_pid = 2;
	proc_list[4].first_child_pid = 0;
	proc_list[4].next_sibling_pid = 0;
	proc_list[4].uid = 5;
	/* for test */
	print_tree(proc_list[find_root(proc_list, num_proc)]);
	return 0;
}
