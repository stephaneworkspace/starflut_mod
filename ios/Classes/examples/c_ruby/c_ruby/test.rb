require 'socket'

puts(Socket)

$SrvGroup = $starruby._GetSrvGroup(0)
Service = $SrvGroup._GetService("","");

puts(Service)
puts($:)

obj = Service._New()
obj._RegScriptProc_P('ttt') {|cleobj,scriptpara| puts(cleobj,scriptpara) }
obj.ttt('asdadasdasdadadaasdsad')