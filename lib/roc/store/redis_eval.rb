class Redis
  
  def eval(script, num_key_args, *args)
    @client.call(:eval, script, num_key_args, *args)
  end

end
