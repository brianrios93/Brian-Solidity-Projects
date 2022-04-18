Crear un sistema para gestionar las transacciones dentro de un parque de diversiones como Disney utilizando un 
token ERC20. Para esto se seguirá la implementación realizada por OpenZepellin con algunos pequeños cambios adaptados a esta
aplicación. 
Este token será generado automáticamente por el contrato de Disney, y utilizado para que los clientes puedan pagar por 
disfrutar atracciones y consumir comidas.
El dueño de este contrato será Disney, y es quien podrá dar de alta y de baja nuevas atracciones y comidas. Luego, 
los clientes comprarán la cantidad de tokens que deseen para pagar las atracciones y las comidas. Al final del paseo, 
podrán devolver los tokens que no hayan utilizado y recuperarán su dinero (en Ethers).
Este contrato tiene una opción para consultar la dirección del contrato del token creado (con nombre DSN) para poder
visualizarlo en la BSCScan, Metamask o donde se lo prefiera.

PD: este sistema representa una mejora respecto al modo tradicional en el que se paga un boleto por todas las atracciones, 
ya que en muchos casos las personas no llegan a utilizarlas todas. De este modo, solo se paga por las que sí se utilizan,
y ahorran dinero.
