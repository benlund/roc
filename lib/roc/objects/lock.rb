module ROC
  class Lock < Time

    def lock(expires_time)
      aquired_lock = false
      if self.setnx(expires_time)
        aquired_lock = true
      else
        locked_until = self.value
        if locked_until.nil? || (locked_until < ::Time.now) ##ttl of 0 is not yet expired
          # only say we got the lock if we manage to update it first
          if self.getset(expires_time) == locked_until
            aquired_lock = true
          end
        end
      end
      aquired_lock
    end

    def locked?
      locked_until = self.value
      !locked_until.nil? && (locked_until >= ::Time.now) ##ttl of 0 is not yet expired
    end
    
    def unlock
      self.forget
    end

    def when_locked(expires_time, poll_ms=100)
      until self.lock(expires_time)
        sleep(poll_ms.to_f / 1000)
      end
      begin
        yield
      ensure
        self.unlock
      end
    end

    def locking_if_necessary(expires_time)
      obtained_lock = self.lock(expires_time)
      begin
        yield
      ensure
        if obtained_lock
          self.unlock
        end
      end      
    end

    def wait_until_not_locked(poll_ms=100)
      until !self.locked?
        sleep(poll_ms.to_f / 1000)
      end
    end

  end
end

