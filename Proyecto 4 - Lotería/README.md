Enunciado: 

Crear un sistema de lotería en los que clientes puedan comprar uno o más boletos con un número, y luego sortear el boleto
ganador. Para ello los clientes pagarán cada boleto con tokens ERC20 generados por este contrato, y dichos tokens se obtienen
pagando con Ethers. Cada vez que un cliente compra un boleto, los tokens irán a la dirección del owner del contrato,
que servirá como caja acumuladora para luego entregar como premio al ganador del sorteo.
La caja de tokens acumulados se hará en la cuenta del owner.
Este contrato tiene una opción para consultar la dirección del contrato del token creado (con nombre DSN) para poder
visualizarlo en la BSCScan, Metamask o donde se lo prefiera.

PD: la ventaja de este sistema es que al estar implementado en la blockchain, se elimina la posibilidad de fraude por parte
de los organizadores ya que los registros de jugadores de la lotería serán totalmente públicos.
