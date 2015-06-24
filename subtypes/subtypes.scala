abstract sealed class Term
case class Var(ind: Int) extends Term
case class Fun(body: Term) extends Term
case class App(f:Term, v: Term) extends Term

case class Closure (term: Term, env: List[Closure])

def eval(c : Closure) : Fun = c match { case Closure(term, env) => term match {
  case Fun(b) => Fun(b)
  case App(m, n) => eval(Closure(m,env)) match { case Fun(b) => eval(Closure(b,Closure(n,env)::env)) } 
  case Var(n) => eval(env(n))
}}

Console.print(eval(Closure(Fun(Var(0)), List())))
