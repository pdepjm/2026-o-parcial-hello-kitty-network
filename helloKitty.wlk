class Paquete {
  const encabezados
  var bytes
  var esUrgente
  
  method reducirPesoPorcentual(reduccion) {
    bytes *= (100 - reduccion) / 100
  }
  
  method incrementarPeso(cantidad) {
    bytes += cantidad
  }


  // El .copy() de .clonNoUrgente() es muy sutil, está porque
  // si un clonador tiene 3 enlaces, les va a enviar a los 3 copias de este paquete, y si enlaces son todos etiquetadores,
  // esos nodos van a agregarle a los encabezados del paquete su etiqueta. El problema está en que
  // , si no hago este .copy(), la instancia de la lista va a ser la misma para los 3 paquetes clonados,
  // por lo que los 3 etiquetadores van a estar modificando la misma lista, lo cual tiene efecto sobre los 3 paquetes,
  // porque todos comparten la misma lista. Entonces, cada clon del paquete debe tener su propia copia de la lista original.
  // El .copy() devuelve una nueva lista con los mismos elementos que la original.

  // Claramente esto es algo dificil ver durante el parcial, por lo que no está mal que no esté en la solucion.
  method clonNoUrgente() = new Paquete(encabezados = encabezados.copy(), esUrgente=false, bytes=bytes)

  method agregarEtiqueta(etiqueta) {
  encabezados.add(etiqueta)
  }
  
  method esUrgente() = esUrgente
  
  method peso() = bytes
}

class Red {
  const nodoEntrada
  
  method enviar(paquete) {
    nodoEntrada.procesar(paquete)
  }

  method paquetesEntregados() = nodoEntrada.paquetesEntregados()

  method bytesUrgentes() = self.paquetesEntregados().filter({paquete => paquete.esUrgente()}).sum({paquete => paquete.peso()})

  method latenciaCritica() = nodoEntrada.latenciaCritica()

}


class NodoSimple {
  var enlace = sinEnlace
  
  method procesar(paquete) {
    self.modificacion(paquete)
    enlace.procesar(paquete)
  }
  
  method enlazarCon(nuevoEnlace) {
    enlace = nuevoEnlace
  }

  method paquetesEntregados() = enlace.paquetesEntregados()

  method latenciaCritica() = self.latencia() + enlace.latenciaCritica()
  
  method modificacion(paquete)
  
  method latencia()
}

class Compresor inherits NodoSimple {
  // aca asumo que reduccion es un valor entero, y que tener "50" es reduccion del 50%. 
  // Cualquier otra forma razonable de representar y calcular el porcentaje está bien.
  const reduccion
  
  override method modificacion(paquete) {
    paquete.reducirPesoPorcentual(reduccion)
  }
  
  override method latencia() = 5
}

class Etiquetador inherits NodoSimple {
  const etiqueta
  
  override method modificacion(paquete) {
    paquete.agregarEtiqueta(etiqueta)
    paquete.incrementarPeso(12)
  }
  
  override method latencia() = etiqueta.size() * 0.25
}

class Filtrador inherits NodoSimple {
  const limite
  var paquetesReenviados = 0
  
  override method procesar(paquete) {
    if (self.puedeProcesar(paquete)) {
      super(paquete)
      paquetesReenviados += 1
    }
  }
  
  // Este checkeo de "enlace != sinEnlace" está para asegurar que solo conteé cuando
  // envia el paquete a un nodo real, y no al "sinEnlace". No está muy bueno, pero la alternativa es que
  // cada nodo entienda "esNodoReal()", y aca consultar por eso. Eso no seria una mala decision,
  // pero tampoco es muy elegante. 
  // Cualquier solucion para resolver el checkeo de que el filtrador tenga un enlace "real" es valido.
  
  // Tambien se puede interpretar que el "reenvio" simplemente significa haber pasado el filtro,
  // por lo que no hace falta verificar si el paquete efectivamente se manda a un nodo real.
  // En el caso de que se interprete algo como esto en otro parcial, es preferible que lo consulten
  // con un docente o por lo menos dejar por escrito esa suposicion.
  // En general, no se vale decir "profeeee yo interprete otra cosaaa" si no está escrito como comentario o validado
  // por un docente durante el parcial.  
  method puedeProcesar(paquete) = (paquete.esUrgente() or paquete.peso() <= limite) and enlace != sinEnlace
  
  override method modificacion(paquete) {
    paquete.agregarEtiqueta("validado")
  }

  override method latencia() = 0.1 * paquetesReenviados
}


class Clonador {
  const enlaces = []
  const paquetesRetenidos = []

  method agregarEnlace(nuevoEnlace){
    paquetesRetenidos.forEach({paquete => nuevoEnlace.procesar(paquete)})
    paquetesRetenidos.clear()
    enlaces.add(nuevoEnlace)
  }

  method procesar(paquete){
    if(enlaces.isEmpty()){
      paquetesRetenidos.add(paquete)
    }
    else{
      enlaces.forEach({enlace => enlace.procesar(paquete.clonNoUrgente())})
    }
  }

  method quitarEnlace(enlace) {
    enlaces.remove(enlace)
  }

  method latencia() = 2 * enlaces.size()

  method latenciaCritica() =
    if (enlaces.isEmpty()) 0
    else self.latencia() + enlaces.map({enlace => enlace.latenciaCritica()}).max()

  // flatMap es lo mismo que map().flatten(). Convierte [[1,2,3],[4,5,6]] en [1,2,3,4,5,6] 
  // asSet() está porque pueden haber varias caminos que lleven a la misma cola de salida,
  // lo cual traeria paquetes duplicados. asSet() saca los elementos duplicados.
  // Como es algo dificil de darse cuenta, no está mal que no se haya considerado en la solucion.
  method paquetesEntregados() = enlaces.flatMap({enlace => enlace.paquetesEntregados()}).asSet()

}


//Para evitar checkeos de null. Está bueno que esté en la solucion, pero no es fundamental.
object sinEnlace { 
  method procesar(paquete) {
    
  }

  method paquetesEntregados() = []

  method latenciaCritica() = 0
}


class ColaDeSalida {
  const paquetesEntregados = []
  
  method procesar(paquete) {
    paquetesEntregados.add(paquete)
  }

  method paquetesEntregados() = paquetesEntregados

  method latenciaCritica() = 0
}


// PARTE C


/*
* No hace falta haber escrito todo esto para que la parte C sea considerada correcta, 
* pero los problemas y el diseño alternativo esperado es el siguiente:


* En primer lugar, el MonitorDeCongestion es innecesario. Cada nodo deberia decidir si congestionarse
* durante la ejecucion de procesar(), donde, si el paquete es pesado, deberia congestionarse por si solo.
* El reinicio deberia ser realizado por la red, la cual le podria enviar un mensaje .reiniciarRed() al nodo
* inicial, el cual se pondrá normal, y le reenviara ese mensaje a su nodo siguiente, y asi con todos los nodos.

* Representar el estado de los nodos mediante herencia es incorrecto
* porque un objeto no puede cambiar de clase durante la ejecucion del programa.
* El diseño plantea una logica innecesariamente compleja para resolver el cambio de estado.
* Se deberia resolver por composicion, donde cada Nodo tiene un atributo estado que represente su
* estado actual (normal, congestionado, caido). 
* La logica de procesamiento de paquetes llamaria a ese estado para ejecutar un procesamiento adicional
* si lo hubiese (en el caso de congestionado) y para validar si puede o no procesar paquetes (en el caso de caido).
* El calculo de la latencia tambien está afectado por el estado, asi que calcular la latencia tambien implica llamar al estado. 
*/

// La solucion con estados se podría ver asi:

/*

object normal {
  method procesamientoAdicional(paquete) {}
  method puedeProcesar(paquete) = true
  method latencia(latenciaBase) = latenciaBase
}

object congestionado {

  method procesamientoAdicional(paquete){
    paquete.agregarEtiqueta("ECN")
  }

  method puedeProcesar(paquete) = true

  method latencia(latenciaBase) = latenciaBase * 2
}


object caido {
  method procesamientoAdicional(paquete){}

  method puedeProcesar(paquete) = false

  method latencia(latenciaBase) = 0
}

class Nodo{
  var tipo = normal

  method latencia() = tipo.latencia(self.latenciaBase()) 

  method procesarPaquete(paquete){
    if(!tipo.puedeProcesar(paquete)){
      return
    }
    tipo.procesamientoAdicional(paquete)
    
    // ...toda la logica anterior

  }

}

*/

// Dependiendo de la solución, podria tener sentido que Clonador herede de NodoConTipo.


