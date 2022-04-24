/*Enunciado: 

Crear un sistema en el que la OMS (Organización mundial de la salud) pueda autorizar a distintos centros de salud a realizar
PCR para la detección de Covid 19 en pacientes. Para esto, un centro de salud con su propia dirección entrará al contrato
de la OMS y solicitará autorización. La OMS, en base a sus propios procedimientos, podrá aprobar la solicitud de cada
centro y crear un nuevo contrato en el que el owner será dicho centro de salud. En este contrato podrá registrar los
resultados del PCR de cada uno de sus pacientes y luego publicar los resultados (Positivo o Negativo) junto al código
de un fichero de IPFS para ver el diagnóstico en detalle.
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

contract OMS_COVID{

    //Dirección de la OMS
    address public owner;

    constructor() public{
        owner = msg.sender;
    }

    //Lista de los centros de salud que solicitan autorización para realizar PCR (crear su Smart Contract)
    address[] Solicitudes;

    //Lista de los contratos de centros de salud autorizados
    address[] public contratos_centros_autorizados;

    //Relacionar los centros de salud con estado de autorización
    mapping(address => bool) public map_autorizado; //TRUE si la OMS lo autorizó, FALSE si no lo autorizó

    //Relacionar la dirección de un centro de salud con su contrato creado
    mapping(address => address) public map_centrosalud;

    //Solicitud de autorización
    event SolicitudAcceso(address);
    //Autorización de un nuevo centro de salud (previo a crear el contrato)
    event nuevo_centro_validado(address);
    //Creación del contrato del nuevo centro de salud
    event nuevo_contrato(address, address); //Dirección del contrato y del owner (el nuevo centro de salud autorizado)
    
    
    //Función para solicitar autorización para realizar PCR
    function SolicitarAcceso() public{
        Solicitudes.push(msg.sender);
        emit SolicitudAcceso(msg.sender);
    }

    //Visualizar las solicitudes de autorización
    function VerSolicitudes() public view solo_OMS(msg.sender) returns(address[] memory) {
        return Solicitudes;
    }

    //Autorizar nuevo centro de salud
    function validar_centro(address _direccion) public solo_OMS(msg.sender){
        map_autorizado[_direccion] = true;
        emit nuevo_centro_validado(_direccion);
    }

    //Crear smart contract del nuevo centro de salud autorizado
    //La ejecuta el centro de salud (no la OMS), solo por decisión del curso. Pero podría crearse cuando se valida el centro.
    function FactoryCentroSalud() public{
       
        require(map_autorizado[msg.sender] == true, "Centro de salud no autorizado para esta operacion");
        
        //Generar el smart contract y enviar la dirección del centro de salud (sender que ejecuta esta función)
        address contrato_centrosalud = address (new CentroSalud(msg.sender));
        //Guardar la dirección de este nuevo contrato en la lista correspondiente
        contratos_centros_autorizados.push(contrato_centrosalud);
        //Relacionar la dirección del centro de salud con su contrato creado
        map_centrosalud[msg.sender] = contrato_centrosalud;
       
        emit nuevo_contrato(contrato_centrosalud, msg.sender);
    }

    //Restringir funciones solo al dueño del contrato
    modifier solo_OMS(address _direccion){
        require(_direccion == owner, "No tienes autorizacion para ejecutar esta funcion");
        _;
    }

}

//Contrato autogestionable por el centro de salud
contract CentroSalud{

    //Direcciones del contrato y del owner (centro de salud)
    address public DireccionContrato;
    address public DireccionCentroSalud; 

    constructor(address _direccion) public{
        DireccionCentroSalud = _direccion;
        DireccionContrato = address(this);
    }

    //Información sobre el resultado del PCR
    struct resultado{
        bool diagnostico;   //True -> Positivo de Covid. False -> Negativo de Covid
        string codigoIPFS;  //Código IPFS del archivo PDF del diagnóstico
    }

    //Relación entre el hash de la dirección de una persona con los resultados del PCR
    //Se utiliza el hash para darle un nivel mayor de seguridad a la identidad de una persona
    mapping(bytes32 => resultado) map_resultado;

    //Evento del resultado: Código IPFS del PCR y resultado del mismo
    event nuevo_resultado(string, bool);

    //Restringir funciona solo para el centro de salud dueño de este contrato
    modifier solo_centrosalud(address _direccion){
        require(_direccion == DireccionCentroSalud, "No tienes permisos para ejecutar esta funcion");
        _;
    }

    //Registrar resultado de un PCR
    /*Ejemplo de datos a recibir: | 1234X | true | QmakwftTJcPRvVqgNkdaZjY7KoiMNcEQL1ntwCi7dbvekT   
    (ID de la persona || Resultado del PCR (Positivo o Negativo) || Código IPFS del PCR)
    */
    //PD: el bool del resultado se debería reemplazar por un string para restringir los datos de ingreso a "true" o "false"
    function resultado_testeo
        (string memory _idPersona, 
        bool _resultadoCovid, 
        string memory _codigoIPFS) 
        public solo_centrosalud(msg.sender){

            require(_resultadoCovid == true || _resultadoCovid == false, "Error, solo 'true' o 'false' como entradas permitidas");

            //Hash de la identificación de la persona
            bytes32 hash_idPersona = keccak256(abi.encodePacked(_idPersona));

            //Relación entre el hash de una persona con el resultado de su testeo y el código IPFS
            map_resultado[hash_idPersona] = resultado(_resultadoCovid, _codigoIPFS);

            //Evento de registrar un nuevo resultado de testeo
            emit nuevo_resultado(_codigoIPFS, _resultadoCovid);
    }

    //Visualizar resultado del PCR de un paciente
    function ver_resultado(string memory _idPersona) public view returns
    (string memory _resultado_prueba, string memory _codigoIPFS){
        //Hash de la identidad de la persona
        bytes32 hash_idPersona = keccak256(abi.encodePacked(_idPersona));
        //Obtenemos el resultado de su testeo

        if(map_resultado[hash_idPersona].diagnostico == true){
            _resultado_prueba = "Positivo";
        }
        else{
            _resultado_prueba = "Negativo";
        }
        _codigoIPFS = map_resultado[hash_idPersona].codigoIPFS;
    } 
}
