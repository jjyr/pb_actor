require 'pb_actor'

def wait_until wait_time = 3
  timeout wait_time do
    sleep 0.1 until yield
  end
end
