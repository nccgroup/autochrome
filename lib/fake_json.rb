class Object
 def to_json
   to_s
 end
end

class Hash
 def to_json
   if empty?
     "{}"
   else
     "{ " + map{|k,v| "#{k.to_json} : #{v.to_json}"}.join(" , ") + " }"
   end
 end
end

class Array
 def to_json
   if empty?
     "[]"
   else
     "[ " + map(&:to_json).join(" , ") + " ]"
   end
 end
end

class NilClass
 def to_json
   "null"
 end
end

class String
 def to_json
   dump
 end
end
