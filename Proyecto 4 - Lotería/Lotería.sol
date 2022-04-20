/*
Enunciado: 
Crear un sistema de lotería en los que clientes puedan comprar uno o más boletos con un número, y luego sortear el boleto
ganador. Para ello los clientes pagarán cada boleto con tokens ERC20 generados por este contrato, y dichos tokens se obtienen
pagando con Ethers. Cada vez que un cliente compra un boleto, los tokens irán a la dirección del owner del contrato,
que servirá como caja acumuladora para luego entregar como premio al ganador del sorteo.
La caja de tokens acumulados se hará en la cuenta del owner.

PD: la ventaja de este sistema es que al estar implementado en la blockchain, se elimina la posibilidad de fraude por parte
de los organizadores ya que los registros de jugadores de la lotería serán totalmente públicos.
*/

// SPDX-License-Identifier: MIT
pragma solidity >0.4.4 <0.7.0;
pragma experimental ABIEncoderV2;
import "./ERC20.sol";

contract Loteria{

    //Instancia del contrato token
    ERC20Basic private token;

    //Dirección de la empresa de Lotería (owner)
    address public owner;

    //Valor de cambio de moneda Token/Ether. Valor 1 equivale a 0.01 Ether, valor 100 equivale a 100 Ether
    //Se trabaja con fracciones de Ether porque los Faucet de internet existentes entregan solo fracciones de Ether.
    uint valortoken;                

    address public direccion_token; //Dirección del contrato del token

    uint public precio_ticket; //Precio al que se cobrará el ticket de lotería. Por ej: 5 tokens

    constructor(uint _totaltokens, uint _valortoken, uint _precio_ticket) public{
        token = new ERC20Basic(_totaltokens, "Loteria Token", "LOT"); //Creación del token
        valortoken = _valortoken;
        direccion_token = address(token);
        precio_ticket = _precio_ticket;
        owner = msg.sender;
    }

    //------------------------------------------ GESTIÓN DEL TOKEN ------------------------------------------------

    //Eventos
    event ev_comprar_tokens(uint, address);
    event ev_devolver_tokens(uint, address);  //Evento para devolver tokens

    //Establecer el precio de un token
    function precio_token(uint _numTokens) internal view returns(uint){
        return _numTokens*valortoken*(0.01 ether);
    }
    
    //Función generar más tokens
    function generar_tokens(uint _numTokens) public Solo_owner(msg.sender){
        token.increaseTotalSupply(_numTokens);
    }

    //Mostrar los tokens disponibles
    function tokens_disponibles() public view returns(uint){
        return token.balanceOf(address(this));
    }

    //El cliente paga con Ethers y recibe tokens
    function comprar_tokens(uint _numTokens) public payable{

        //Verificar que el comprador posea el dinero suficiente para comprar los tokens que especifica
        require(precio_token(_numTokens) <= msg.value, "Monto insuficiente. Ingrese más Ethers o compre menos tokens");

        //Verificar que exista la cantidad de tokens disponibles que desea comprar
        require(_numTokens <= tokens_disponibles(), "No se dispone de esa cantidad de tokens. Ingrese un número menor");

        //Devolución en Ethers al cliente. Diferencia entre lo que pagó y lo que cuesta la cantidad de tokens que compró
        msg.sender.transfer(msg.value-precio_token(_numTokens));

        //Realizar la transferencia de tokens desde el contrato al cliente
        token.transfer(msg.sender, _numTokens);

        //Evento de compra de tokens
        emit ev_comprar_tokens(_numTokens, msg.sender);
    }

    //Consultar el balance de tokens actual
    function mis_tokens() public view returns(uint){
        return token.balanceOf(msg.sender);
    }

    //El cliente devuelve los tokens a este contrato y recibe el correspondiente valor en Ethers
    function devolver_tokens(uint _numTokens) public{

        //require(_numTokens > 0, "Ingrese una cantidad de tokens mayor a cero");

        require(_numTokens <= token.balanceOf(msg.sender),"Error. Ingrese una cantidad menor o igual a los tokens que posee");

        //Devolver los tokens al Smart Contract de la Loteria:
        token.transferClient(msg.sender, address(this), _numTokens);

        /*Transferir la cantidad equivalente de los tokens en Ethers al cliente. La función precio_tokens se
        encarga de hacer la conversión
        */
        msg.sender.transfer(precio_token(_numTokens));

        //Evento de devolución de tokens
        emit ev_devolver_tokens(_numTokens, msg.sender);
    }

    //Obtener el balance de tokens acumulados en la caja de la lotería
    function acumulado() public view returns(uint){
        return token.balanceOf(owner);
    }

    //Restringir funciones solo al dueño del contrato
    modifier Solo_owner(address _direccion){
        require (_direccion == owner, "No tienes autorización para ejecutar esta función");
        _;
    }

    //------------------------------------------- GESTIÓN DE LA LOTERIA ---------------------------------------

    //Recordar que el precio del token está inicializado en el Constructor

    //Relación entre una persona y los números de los boletos que ha comprado
    mapping(address => uint []) map_misBoletos; //Puede haber comprado más de un boleto, por eso el arrray

    //Relación entre boleto ganador y dirección del cliente que lo haga comprado (cliente ganador)
    mapping(uint => address) map_boletosPersona;

    //Número ganador aleatorio
    uint randNonce = 0;

    //Lista de todos los boletos generados
    uint [] boletos_comprados;

    //Eventos
    event ev_comprar_boleto(uint, address);         //Evento de compra de un boleto
    event ev_boleto_ganador(uint, address, uint);      //Evento del ganador

    //Función para comprar boletos. No se podrá elegir el número del boleto, solo la cantidad a comprar.
    function comprar_boletos(uint _cantBoletos) public{
        //Precio total boletos
        uint precio_total = precio_ticket*_cantBoletos;

        //Verificar que el cliente pueda comprar los boletos
        require(precio_total <= token.balanceOf(msg.sender),"Tokens insuficientes para realizar esta compra");

        //Transferir los tokens desde el cliente hacia el owner (caja acumulada)
        token.transferClient(msg.sender, owner, precio_total);

        //Generamos uno o más números aleatorios, según la cantidad de boletos comprados
        for(uint i=0; i < _cantBoletos; i++){
            
            /*Generar un número aleatorio a través del hash de varios elementos: la hora actual, la dirección del cliente,
            y randnonce, que es un contador que se incrementa en 1 cada vez que se genera un boleto. Luego se obtiene
            las últimas 4 cifras y se asigna como número del boleto*/
            uint random = uint(keccak256(abi.encodePacked(now, msg.sender, randNonce))) % 10000;
            randNonce++;

            //Asociar a la persona con su boleto comprado
            map_misBoletos[msg.sender].push(random);
            //Anotar el boleto en la lista de boletos generados
            boletos_comprados.push(random);
            //Anotar la persona que compró este boleto (nos servirá para identificar a la persona del boleto ganador)
            map_boletosPersona[random] = msg.sender;
            //Emitir el evento de compra de boletos
            emit ev_comprar_boleto(random, msg.sender);
        }
    }

    //Visualizar los boletos que el cliente compró
    function mis_boletos() public view returns (uint [] memory){
        return map_misBoletos[msg.sender];
    }

    //Número del boleto ganador
    uint boleto_ganador;
    //Dirección del cliente que compró el boleto ganador
    address cliente_ganador;

    //Generar boleto ganador
    function sorteo_ganador() public Solo_owner(msg.sender){

        //Evaluamos que existan boletos comprados antes de ejecutar esta función
        require(boletos_comprados.length > 0, "Aún no hay boletos comprados");
        //Obtenemos la cantidad total de boletos generados
        uint longitud = boletos_comprados.length;
        //Obtenemos un número aleatorio desde 0 a la cantidad de boletos generados, y será la posición del boleto ganador
        uint posicion_ganador = uint(keccak256(abi.encodePacked(now))) % longitud;
    
        //Registramos el boleto ganador y la dirección del cliente que lo compró
        boleto_ganador = boletos_comprados[posicion_ganador];
        
        cliente_ganador = map_boletosPersona[boleto_ganador];

        //Enviar los tokens al cliente ganador como premio
        token.transferClient(owner, cliente_ganador, acumulado());
        //Evento del boleto ganador
        emit ev_boleto_ganador(boleto_ganador, cliente_ganador, acumulado());
    }

    function ver_ganador() public view returns(uint, address){
        return (boleto_ganador, cliente_ganador);
    }
}
