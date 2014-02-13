function Env(pa_env)
   pa_env = pa_env or {}
   local o = {}
   local mt = {__index=pa_env}
   setmetatable(o, mt)
   return o
end

function Var(name)
   local o = {type='var', name=name}
   return o
end

function Lambda(arg, body)
   local o = {type='lambda', arg=arg, body=body}
   return o
end

function Apply(func, arg)
   local o = {type='apply', func=func, arg=arg}
   return o
end

Parser = {}
function Parser:new(tokens)
   self.i = 1
   self.tokens = tokens
   return self
end

function Parser:nextToken()
   local o = self.tokens[self.i]
   self.i = self.i + 1
   return o
end

function Parser:lookahead()
   local o = self.tokens[self.i]
   return o
end

function Parser:match(s)
   if self:lookahead() ~= s then
      error(s .. "not match")
   end
   self:nextToken()
end

function Parser:parseVAR()
   local var = Var(self:nextToken())
   return var
end

function Parser:parseEXPR()
   if not self:lookahead() then
      return
   end
   if self:lookahead() == "^" then
      self:match("^")
      local arg = self:parseVAR()
      self:match(".")
      local expr = self:parseAPPL()
      return Lambda(arg, expr)
   elseif self:lookahead() == "(" then
      self:match("(")
      local expr = self:parseAPPL()
      self:match(")")
      return expr
   elseif self:lookahead() ~= ")" then
      return self:parseVAR()
   end
end

function Parser:parseAPPL()
   if self:lookahead() == ")" then
      return
   elseif self:lookahead() then
      local exprs = {}, x
      exprs[1] = self:parseEXPR()
      while true do
         local expr = self:parseEXPR()
         if expr then
            exprs[#exprs+1] =expr
         else
            break
         end
      end
      x = exprs[1]
      for i=2, #exprs do
         if exprs[i] then
            x = Apply(x, exprs[i])
         end
      end
      return x
   end
end

function Parser:parse()
   return self:parseAPPL()
end

function lexer(s)
   local tokens = {}
   local i, st, en
   i = 1
   while i <= #s do
      local c = s:sub(i, i)
      st, en = nil, nil
      if c=='^' or c=='.' or c=='(' or c==')' then
         st, en = i, i
      elseif c:match("%a") == c then
         st, en = s:find("%a+", i)
      end
      if st then
         tokens[#tokens+1] = s:sub(st, en)
         i = en + 1
      else
         i = i + 1
      end
   end
   return tokens
end

function printTokens(tokens)
   for i=1, #tokens do
      print(tokens[i])
   end
end

function printAST(ast)
   if ast.type == 'lambda' then
      io.write('^')
      printAST(ast.arg)
      io.write('.')
      io.write('(')
      printAST(ast.body)
      io.write(')')
   elseif ast.type == 'apply' then
      io.write('(')
      printAST(ast.func)
      io.write(' ')
      printAST(ast.arg)
      io.write(')')
   elseif ast.type == 'var' then
      io.write(ast.name)
   end
end

function eval(expr, env)
   if expr.type == "var" then
      return env[expr.name] or expr
   elseif expr.type == "lambda" then
      local new_env = Env(env)
      new_env[expr.arg.name] = expr.arg
      return Lambda(expr.arg, eval(expr.body, new_env))
   elseif expr.type == "apply" then
      local a = eval(expr.func, env)
      local b = eval(expr.arg, env)
      if a.type == "lambda" then
         env[a.arg.name] = b
         return eval(a.body, env)
      else
         return Apply(a, b)
      end
   end
end

function repl()
   io.write("<<< ")
   s = io.read()
   while s do
      local toks = lexer(s)
      local p = Parser:new(toks)
      local a = p:parse()
      if a then
         local c = eval(a, Env())
         io.write(">>> ")
         printAST(c)
         print('\n')
      end
      io.write("<<< ")
      s = io.read()
   end
end

repl()
