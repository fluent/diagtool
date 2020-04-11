require './maskutils'
include Diagtool

#line = '2020-02-26 19:10:31 -0500 [warn] #0 failed to flush the buffer. retry_time=0 next_retry_seconds=2020-02-26 19:10:32 -0500 chunk="59f838c7b432e47585ad3028384d79eb" error_class=Errno::ECONNREFUSED error="Connection refused - connect(2) for \"192.168.56.12\" port 24224"'
#line = '2020-02-26 19:10:29 -0500 [info] #0 adding forwarding server \'192.168.56.12:24224\' host=ipv4_md5_28b515a0b563a5ac476cc331b75963d0 port=24224 weight=60 plugin_id="object:3fefc3f961c0"'
#line = '2020-02-21 19:05:50 -0500 [info] #0 [input_debug_agent] listening dRuby uri=\"dRuby://127.0.0.1:24230\" object="Fluent::Engine" worker=0'
#line = '2020-02-21 19:05:50 -0500 [info] #0 [input_debug_agent] listening dRuby "http://127.0.0.1:24230" object="Fluent::Engine" worker=0'
#line = '2020-02-21 18:18:21 -0500 [info] #0 [input_debug_agent] listening dRuby uri="druby://127.0.0.1:24230" object="Fluent::Engine" worker=0'
#line = '2020-02-26 19:29:04 -0500 [warn]: #0 failed to flush the buffer. retry_time=0 next_retry_seconds=2020-02-26 19:29:05 -0500 chunk="59f83cec70850e4c397d705c6801c021" error_class=Fluent::Plugin::ForwardOutput::NoNodesAvailable error="no nodes are available"'
#line = '2019-07-04 18:28:38 -0400 [info]: rdkafka: [thrd://sasl_ssl://bdtbelr6n15.svr.us.jpmchase.net:9093/bootstrap] sasl_ssl://fqdn_md5_f416432ec94d011552d35b181e87d04f:9093/bootstrap Feature MsgVer1: Produce (2..2) supported by broker'
#line = '2019-07-04 18:28:38 -0400 [info]: rdkafka: [thrd://sasl_ssl://bdtbelr6n15.svr.us.jpmchase.net] sasl_ssl://fqdn_md5_f416432ec94d011552d35b181e87d04f:9093/bootstrap Feature MsgVer1: Produce (2..2) supported by broker'
line = 'brokers bdtbelr6n15.svr.us.demo.net:9093,bdtbelr6n16.svr.us.demo.net:9093,bdtbelr7n4.svr.us.demo.net:9093,bdtbelr7n5.svr.us.demo.net:9093,bdtbelr7n6.svr.us.demo.net:9093'
#line ='2019-07-04 18:27:44 -0400 [info]: rdkafka: [thrd:app]: Selected provider Cyrus for SASL mechanism GSSAPI'
#line = '/root/work/logfile/logs_0542CT/td-agent-out16.log.mask:2019-07-04 18:31:25 -0400 [info]: rdkafka: [thrd:sasl_ssl://fqdn_md5_a9e20b1ee10372643186ce6185608ad4:9093/bootstrap] sasl_ssl://fqdn_md5_a9e20b1ee10372643186ce6185608ad4:9093/bootstrap Refreshing SASL keys with command: kinit -S "kafka_confluent/bdtbelr7n6.svr.us.jpmchase.net" -k -t "/home/a_slp_np/a_slp_np.keytab" a_slp_np@NAEAST.AD.JPMORGANCHASE.COM'

#line = '2019-07-04 18:29:05 -0400 [info]: rdkafka: [thrd:sasl_ssl://tkubota.demo.com:9093/bootstrap]: sasl_ssl://tkubota.demo.com:9093/bootstrap: Refreshing SASL keys with command: kinit -S "kafka_confluent/tkubota.demo.com" -k -t "/home/a_slp_np/a_slp_np.keytab" a_slp_np@tkubota.demo.com'

exlist=[]
hash = 'tkubota'
line_id = 0
mask1 = Maskutils.new(exlist, hash, 'DEBUG')
p mask1.mask_tdlog_inspector(line)
p mask1.get_maskdb()
