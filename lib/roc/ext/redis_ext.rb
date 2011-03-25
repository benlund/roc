class Redis

  def zrevrangebyscore(key, max, min, options = {})
    command = CommandOptions.new(options) do |c|
      c.splat :limit
      c.bool  :with_scores
    end

    @client.call(:zrevrangebyscore, key, max, min, *command.to_a)
  end

  def del(*keys)
    _bool @client.call(:del, *keys)
  end

  def hdel(key, field)
    _bool @client.call(:hdel, key, field)
  end

end
