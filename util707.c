/*
 *   This file is part of tk707.
 *
 *   Copyright (C) 2000, 2001, 2002, 2003, 2004 Chris Willing and Pierre Saramito 
 *
 *   tk707 is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation; either version 2 of the License, or
 *   (at your option) any later version.
 *
 *   Foobar is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with Foobar; if not, write to the Free Software
 *   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */
#include <string.h>
#include "util707.h"

int
seq707_context_init(seq707_context_t **ctxp)
{
	if( (*ctxp=(seq707_context_t*)calloc(1, sizeof(seq707_context_t))) == NULL )
		return -1;
	(*ctxp)->ppq = PPQ;
	(*ctxp)->currticktime = 0;
	(*ctxp)->tempo = 500000;
	(*ctxp)->midichannel = DEF_MIDICHANNEL;

return 0;
}

int
usage(void)
{
	fprintf(stderr, "\nusage:\ttk707 [options]\nwhere option:\n");
	fprintf(stderr, "        -l            provides list of ports\n");
	fprintf(stderr, "        -p x:y        specifies x:y as port to use, e.g. 64:0\n\n");
#ifdef TODO
       -h
       -l     List the available sound ports
       -p port
       -colormap
       -display
       -geometry
       -name  Name to use for application
       -sync  Use synchronous mode for display server
       -visual
       -use   Id of window in which to embed application
       --     Pass all remaining arguments through to script
#endif /* TODO */

#ifdef TO_CLEAN
	printf("NOTE:\n");
	printf("        Setting ALSA_OUT_PORT=x:y allows tk707 to run without -p option.\n");
	printf("        Try \"export ALSA_OUT_PORT=x:y\" in .profile (or /etc/profile),\n");
	printf("where x:y is a port generated with -l option.\n\n");
#endif /* TO_CLEAN */

        return 0;
}

int
set_client_port(char *portdesc, int *client, int *port)
{
	char *astr;
	char *cp;
	snd_seq_addr_t *addr;
	snd_seq_addr_t *ap;
	int a[ADDR_PARTS];
	int count, naddr;
	int i;

	addr = (snd_seq_addr_t*)calloc((unsigned)(sizeof(snd_seq_addr_t)*strlen(portdesc)), 1);
	if( !addr )
		return -1;

	naddr = 0;
	ap = addr;

	for(astr=strtok(portdesc,SEP);astr;astr=strtok(NULL,SEP)) {
		for(cp=astr,count=0;cp && *cp;cp++) {
			if( count < ADDR_PARTS )
				a[count++] = atoi(cp);
			cp = strchr(cp, ':');
			if( cp == NULL )
				break;
		}

		switch(count)
		{
			case 2:
				ap->client = a[0];
				ap->port = a[1];
				break;
			default:
				printf("Addresses in %d parts not supported yet\n", count);
				break;
		}
		ap++;
		naddr++;
	}
	*client = a[0];
	*port = a[1];

return 0;
}


#ifdef HAVE_ALSA9
/* ALSA 0.9.0 API */
int
get_clientsports(char ***cpinfo)
{
	snd_seq_client_info_t *cinfo;
	snd_seq_port_info_t *pinfo;
	snd_seq_t *handle;
	int  client, port, cp, i;
	char buf[128];

	if (snd_seq_open(&handle, "hw", SND_SEQ_OPEN_DUPLEX, 0) < 0)
	{
		fprintf(stderr, "Couldn't open sequence. Error was:\n%s\n", snd_strerror(errno));
		return -1;
	}
	snd_seq_client_info_alloca(&cinfo);
	snd_seq_port_info_alloca(&pinfo);
	cp = 0;
	printf("Port     %-30.30s    %s\n", "Client name", "Port name");
	snd_seq_client_info_set_client(cinfo, 0);
	while (snd_seq_query_next_client(handle, cinfo) >= 0) {
		client = snd_seq_client_info_get_client(cinfo);
		snd_seq_port_info_set_client(pinfo, client);
		snd_seq_port_info_set_port(pinfo, -1);
		while (snd_seq_query_next_port(handle, pinfo) >= 0) {
			unsigned int cap;
			cap = (SND_SEQ_PORT_CAP_SUBS_WRITE|SND_SEQ_PORT_CAP_WRITE);
			if ((snd_seq_port_info_get_capability(pinfo) & cap) == cap)
				cp++;
		}
	}

	if( (*cpinfo=(char**)calloc(cp + 1, sizeof(char*))) == NULL )
	{
		fprintf(stderr, "Couldn't get memory for client:port info\n");
		return 0;
	}
	/* Now do it again and add each client:port */
	cp = 0;
	snd_seq_client_info_set_client(cinfo, 0);
	while (snd_seq_query_next_client(handle, cinfo) >= 0) {
		client = snd_seq_client_info_get_client(cinfo);
		snd_seq_port_info_set_client(pinfo, client);
		snd_seq_port_info_set_port(pinfo, -1);
		while (snd_seq_query_next_port(handle, pinfo) >= 0) {
			unsigned int cap;
			port = snd_seq_port_info_get_port(pinfo);
			cap = (SND_SEQ_PORT_CAP_SUBS_WRITE|SND_SEQ_PORT_CAP_WRITE);
			if ((snd_seq_port_info_get_capability(pinfo) & cap) == cap) {
				memset(buf, 0, sizeof(buf));
				sprintf(buf, "%3d:%-3d   %-30.30s    %s\n",
					client, port,
					snd_seq_client_info_get_name(cinfo),
					snd_seq_port_info_get_name(pinfo));
				(*cpinfo)[cp] = strdup(buf);
				cp++;
			}
		}
	}
/*
	sprintf(buf, "END END");
	(*cpinfo)[cp] = strdup(buf);
	return cp + 1;
*/
return cp;
}

#else /* !HAVE_ALSA9 */

int
get_clientsports(char ***cpinfo)
{
	snd_seq_client_info_t cinfo;
	snd_seq_port_info_t pinfo;
	snd_seq_system_info_t sysinfo;
	snd_seq_t *handle;
	int  client, port, cp, i;
	char buf[128];

	if( snd_seq_open(&handle, SND_SEQ_OPEN) < 0 )
	{
		fprintf(stderr, "Couldn't open sequence. Error was:\n%s\n", snd_strerror(errno));
		return -1;
	}
	if( snd_seq_system_info(handle, &sysinfo) < 0 )
	{
		fprintf(stderr, "Couldn't get sequencer information. Error was:\n%s\n", snd_strerror(errno));
		return -1;
	}

	cp = 0;
	fprintf(stderr, "Port      %-30.30s    %s\n", "Client name", "Port name");
	/* First just count how many string pointers we'll need */
	for(client=0;client<sysinfo.clients;client++)
	{
		if( snd_seq_get_any_client_info(handle, client, &cinfo) < 0 )
			continue;
		for(port=0;port<sysinfo.ports;port++)
		{
			unsigned int cap;
			if( snd_seq_get_any_port_info(handle, client, port, &pinfo) < 0 )
				continue;
			cap = (SND_SEQ_PORT_CAP_SUBS_WRITE|SND_SEQ_PORT_CAP_WRITE);
			if( (pinfo.capability & cap) == cap )
			{
/*
				printf("%3d:%-3d   %-30.30s    %s\n", pinfo.client, pinfo.port, cinfo.name, pinfo.name);
*/
				cp++;
			}
		}
	}

	if( (*cpinfo=(char**)calloc(cp + 1, sizeof(char*))) == NULL )
	{
		fprintf(stderr, "Couldn't get memory for client:port info\n");
		return 0;
	}
	/* Now do it again and add each client:port */
	cp = 0;
	for(client=0;client<sysinfo.clients;client++)
	{
		if( snd_seq_get_any_client_info(handle, client, &cinfo) < 0 )
			continue;
		for(port=0;port<sysinfo.ports;port++)
		{
			unsigned int cap;
			if( snd_seq_get_any_port_info(handle, client, port, &pinfo) < 0 )
				continue;
			cap = (SND_SEQ_PORT_CAP_SUBS_WRITE|SND_SEQ_PORT_CAP_WRITE);
			if( (pinfo.capability & cap) == cap )
			{
				memset(buf, 0, sizeof(buf));
				sprintf(buf, "%3d:%-3d   %-30.30s    %s\n", pinfo.client, pinfo.port, cinfo.name, pinfo.name);
				(*cpinfo)[cp] = strdup(buf);
				cp++;
			}
		}
	}
/*
	sprintf(buf, "END END");
	(*cpinfo)[cp] = strdup(buf);
	return cp + 1;
*/
return cp;
}

#endif /* HAVE_ALSA9 */

void
set_event_header(seq707_context_t *ctxp, snd_seq_event_t *ev)
{
	snd_seq_ev_clear(ev);
	snd_seq_ev_set_dest(ev, ctxp->dest_client, ctxp->dest_port);
	snd_seq_ev_set_source(ev, ctxp->local_port);

	set_event_time(ctxp, ev, 0);
}

void
set_event_time(seq707_context_t *ctxp, snd_seq_event_t *ev, unsigned int currtime)
{
	if( currtime == 0 )
		currtime = ctxp->currticktime;

	snd_seq_ev_schedule_tick(ev, ctxp->dest_queue, 0, currtime);
/*
printf("Set event time to %u\n", currtime);
*/
}

void
alsa_timer_start(seq707_context_t *ctxp)
{
	snd_seq_start_queue(ctxp->handle, ctxp->dest_queue, NULL);
}

void
alsa_timer_stop(seq707_context_t *ctxp)
{
	snd_seq_event_t ev;

	set_event_header(ctxp, &ev);
	snd_seq_stop_queue(ctxp->handle, ctxp->dest_queue, &ev);
}

void
alsa_timer_cont(seq707_context_t *ctxp)
{
	snd_seq_event_t ev;

	set_event_header(ctxp, &ev);
	snd_seq_continue_queue(ctxp->handle, ctxp->dest_queue, &ev);
}

void
do_noteon(seq707_context_t *ctxp, int chan, int pitch, int vol)
{
	int written;
	snd_seq_event_t ev;
	snd_seq_ev_clear(&ev);

	set_event_header(ctxp, &ev);

	snd_seq_ev_set_noteon(&ev, chan, pitch, vol);
	written = snd_seq_event_output(ctxp->handle, &ev);
	if (written < 0) {
		printf("written = %i (%s)\n", written, snd_strerror(written));
		exit(1);
	}
	/* printf("wrote %d\n", written); */
}
/* Send a note on event to the 2nd queue */
void
do_noteon_rt(seq707_context_t *ctxp, int chan, int pitch, int vol)
{
	int written;
	snd_seq_event_t ev;
	snd_seq_ev_clear(&ev);

	snd_seq_ev_set_dest(&ev, ctxp->dest_client, ctxp->dest_port);
	snd_seq_ev_set_source(&ev, ctxp->local_port);
	snd_seq_ev_schedule_tick(&ev, ctxp->dest_queue, 0, 0);

	snd_seq_ev_set_noteon(&ev, chan, pitch, vol);
	written = snd_seq_event_output(ctxp->handle, &ev);
	if (written < 0) {
		printf("written = %i (%s)\n", written, snd_strerror(written));
		exit(1);
	}
	/* printf("wrote %d to chan %d\n", written, chan); */
}

void
do_noteoff(seq707_context_t *ctxp, int chan, int pitch, int vol)
{
	int written;
	snd_seq_event_t ev;
	snd_seq_ev_clear(&ev);

	set_event_header(ctxp, &ev);

	snd_seq_ev_set_noteoff(&ev, chan, pitch, vol);
	written = snd_seq_event_output(ctxp->handle, &ev);
	if (written < 0) {
		printf("written = %i (%s)\n", written, snd_strerror(written));
		exit(1);
	}
}
/* Send a note off event to the 2nd queue */
void
do_noteoff_rt(seq707_context_t *ctxp, int chan, int pitch, int vol)
{
	int written;
	snd_seq_event_t ev;
	snd_seq_ev_clear(&ev);

	snd_seq_ev_set_dest(&ev, ctxp->dest_client, ctxp->dest_port);
	snd_seq_ev_set_source(&ev, ctxp->local_port);
	snd_seq_ev_schedule_tick(&ev, ctxp->dest_queue, 0, old_tick_per_note_on);

	snd_seq_ev_set_noteoff(&ev, chan, pitch, vol);
	written = snd_seq_event_output(ctxp->handle, &ev);
	if (written < 0) {
		printf("written = %i (%s)\n", written, snd_strerror(written));
		exit(1);
	}
}



snd_seq_event_t *
wait_for_event(seq707_context_t *ctxp)
{
        int left;
        snd_seq_event_t *input_event;
  
        /* read event - blocked until any event is read */
        left = snd_seq_event_input(ctxp->handle, &input_event);

        if (left < 0) {
                printf("alsa_sync error!:%s\n", snd_strerror(left));
                return NULL;
        }

        return input_event;
}

int
do_tempo_set(seq707_context_t *ctxp, unsigned int val)
{
	snd_seq_event_t ev;

	memset(&ev, 0, sizeof(snd_seq_event_t));
	ev.queue = SND_SEQ_QUEUE_DIRECT;
	ev.type = SND_SEQ_EVENT_TEMPO;
	ev.dest.client = SND_SEQ_CLIENT_SYSTEM;
	ev.dest.port = SND_SEQ_PORT_SYSTEM_TIMER;
	ev.data.queue.queue = ctxp->dest_queue;
	ev.data.queue.param.value = val;

	return snd_seq_event_output(ctxp->handle, &ev);
}

int
alsa_setup(TK707 *tk707, char *portdesc, char *in_portdesc)
{
	int c, res, myport, ctrlport, iport, dest_queue, ctrl_queue, input_queue, clientno, portno, ppq;
	int i, bank, pattern;
	snd_seq_t *seq_handle = NULL;
	snd_seq_t *ctrl_handle = NULL;
	snd_seq_t *input_handle = NULL;
#ifdef HAVE_ALSA9
	snd_seq_queue_tempo_t *tempo;
#else
	snd_seq_queue_tempo_t   tempo;
#endif


/* Initialise contexts for pattern & control outputs */
	if( seq707_context_init(&(tk707->ctxp_p)) < 0 )
		return -1;
	if( seq707_context_init(&(tk707->ctxp_c)) < 0 )
		return -1;
	if( seq707_context_init(&(tk707->ctxp_i)) < 0 )
		return -1;

/* Obtain handles to sequencers */
#ifdef HAVE_ALSA9
	if( snd_seq_open(&(tk707->ctxp_p->handle), "hw", SND_SEQ_OPEN_DUPLEX,
			 SND_SEQ_NONBLOCK) < 0 )
		return -1;
	if( snd_seq_open(&(tk707->ctxp_c->handle), "hw", SND_SEQ_OPEN_DUPLEX,
			 SND_SEQ_NONBLOCK) < 0 )
		return -1;
	if( snd_seq_open(&(tk707->ctxp_i->handle), "hw", SND_SEQ_OPEN_DUPLEX,
			 SND_SEQ_NONBLOCK) < 0 )
		return -1;
#else
	if( snd_seq_open(&(tk707->ctxp_p->handle), SND_SEQ_OPEN) < 0 )
		return -1;
	if( snd_seq_open(&(tk707->ctxp_c->handle), SND_SEQ_OPEN) < 0 )
		return -1;
	if( snd_seq_open(&(tk707->ctxp_i->handle), SND_SEQ_OPEN) < 0 )
		return -1;
#endif


	seq_handle = tk707->ctxp_p->handle;
	ctrl_handle = tk707->ctxp_c->handle;
	input_handle = tk707->ctxp_i->handle;

/* Set non-blocking mode for the queues */
#ifndef HAVE_ALSA9
	if( snd_seq_block_mode(seq_handle, 0) < 0 )
		return -1;
	if( snd_seq_block_mode(ctrl_handle, 0) < 0 )
		return -1;
	if( snd_seq_block_mode(input_handle, 0) < 0 )
		return -1;
#endif

/* Textual names for clients */
	snd_seq_set_client_name(seq_handle, "TK707");
	snd_seq_set_client_name(ctrl_handle, "TK707control");
	snd_seq_set_client_name(input_handle, "TK707input");

/* Create the ports */
	if( (myport=snd_seq_create_simple_port(seq_handle, "Port 0",
					SND_SEQ_PORT_CAP_WRITE | SND_SEQ_PORT_CAP_READ,
					SND_SEQ_PORT_TYPE_MIDI_GENERIC)) < 0 )
	{
		return -1;
	}
	if( (ctrlport=snd_seq_create_simple_port(ctrl_handle, "Port 1",
					SND_SEQ_PORT_CAP_WRITE | SND_SEQ_PORT_CAP_READ,
					SND_SEQ_PORT_TYPE_MIDI_GENERIC)) < 0 )
	{
		return -1;
	}
	if( (iport=snd_seq_create_simple_port(input_handle, "Port 2",
					SND_SEQ_PORT_CAP_READ,
					SND_SEQ_PORT_TYPE_MIDI_GENERIC)) < 0 )
	{
		return -1;
	}
	tk707->ctxp_p->local_port = myport;
	tk707->ctxp_c->local_port = ctrlport;
	tk707->ctxp_i->local_port = iport;

/* Allocate destination queues */
	if( (dest_queue=snd_seq_alloc_queue(seq_handle)) < 0 )
		return -1;
	if( (ctrl_queue=snd_seq_alloc_queue(ctrl_handle)) < 0 )
		return -1;
	if( (input_queue=snd_seq_alloc_queue(input_handle)) < 0 )
		return -1;
	tk707->ctxp_p->dest_queue = dest_queue;
	tk707->ctxp_c->dest_queue = ctrl_queue;
	tk707->ctxp_i->dest_queue = input_queue;

/* No more _i's */
/* Set client:port from port descriptor (pattern & control use same) */
	if( set_client_port(portdesc, &clientno, &portno) < 0 )
		return -1;
	tk707->ctxp_p->dest_client = clientno;
	tk707->ctxp_p->dest_port = portno;
	tk707->ctxp_c->dest_client = clientno;
	tk707->ctxp_c->dest_port = portno;

/* Connect the queues */
	if( snd_seq_connect_to(seq_handle, myport, clientno, portno) < 0 )
		return -1;
	if( snd_seq_connect_to(ctrl_handle, ctrlport, clientno, portno) < 0 )
		return -1;
	
/* Set io buffer characteristics */
	if( snd_seq_set_client_pool_output(seq_handle, WRITE_POOL_SIZE) < 0 ||
		snd_seq_set_client_pool_input(seq_handle, READ_POOL_SIZE) < 0 ||
		snd_seq_set_client_pool_output_room(seq_handle, WRITE_POOL_SPACE) < 0 )
	{
		return -1;
	}
	if( snd_seq_set_client_pool_output(ctrl_handle, WRITE_POOL_SIZE) < 0 ||
		snd_seq_set_client_pool_input(ctrl_handle, READ_POOL_SIZE) < 0 ||
		snd_seq_set_client_pool_output_room(ctrl_handle, WRITE_POOL_SPACE) < 0 )
	{
		return -1;
	}

/* Set pattern queue tempo. Control queue doesn't seem to need it (yet?) */
#ifdef HAVE_ALSA9
	snd_seq_queue_tempo_alloca(&tempo);
	if (snd_seq_get_queue_tempo(seq_handle, dest_queue, tempo) < 0 )
		return -1;
	ppq = tk707->ctxp_p->ppq;
	if (snd_seq_queue_tempo_get_ppq(tempo) != ppq )
	{
		snd_seq_queue_tempo_set_ppq(tempo, ppq);
		if( snd_seq_set_queue_tempo(seq_handle, dest_queue, tempo) < 0 )
		{
			return -1;
		}
	}
	tk707->ctxp_p->tempo = snd_seq_queue_tempo_get_tempo(tempo);
#else
	if( snd_seq_get_queue_tempo(seq_handle, dest_queue, &tempo) < 0 )
		return -1;
	ppq = tk707->ctxp_p->ppq;
	if( tempo.ppq != ppq )
	{
		tempo.ppq = ppq;
		if( snd_seq_set_queue_tempo(seq_handle, dest_queue, &tempo) < 0 )
		{
			return -1;
		}
	}
	tk707->ctxp_p->tempo = tempo.tempo;
#endif

return 0;
}
