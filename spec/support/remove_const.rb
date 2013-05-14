def remove_const *names
  names.each { |name| Object.send :remove_const, name }
end
