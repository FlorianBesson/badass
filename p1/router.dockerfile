FROM frrouting/frr:v8.4.1

RUN apk add --no-cache busybox
#activate BGP (border gateway protocal) and IRP (interior routing protocol) for routing in the AS (autonomous system)
RUN sed -i "s/^bgpd=no/bgpd=yes/" /etc/frr/daemons \
  && sed -i "s/^ospfd=no/ospfd=yes/" /etc/frr/daemons \
  && sed -i "s/^isisd=no/isisd=yes/" /etc/frr/daemons
