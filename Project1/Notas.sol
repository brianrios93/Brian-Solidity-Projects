//Especificamos una licencia que conviene usar
// SPDX-Licence-Identifier: MIT
pragma solidity >=0.4.4 <0.7.0;
pragma experimental ABIEncoderV2;

// -----------------------------------
//  ALUMNO   |    ID    |      NOTA
// -----------------------------------
//  Marcos |    77755N    |      5
//  Joan   |    12345X    |      9
//  Maria  |    02468T    |      2
//  Marta  |    13579U    |      3
//  Alba   |    98765Z    |      5


contract Notas{

    /*Necesitamos tener a mano la dirección del profesor que publicará las notas. Guardaremos el dato, y será el
    propietario del contrato, o sea quien lo despliega.
    */

    //Dirección del profesor, y nos interesa que sea pública para poder chequearla
    address public profesor;

    constructor() public{
        profesor = msg.sender;
    }

    /*Queremos que las notas se relacionen con la identidad de un alumno. Para eso utilizaremos el hash de la identidad del
    alumno (y por lo tanto será una variable de 32bytes). Lo que aún no sé, es por qué un hash y no un simple ID, pero
    puede que sea para preservar su identidad. 
    Rpta: al subir esta información sensible a una blockchain pública, queremos cuidar de que alguien con malas intenciones
    la puerta leer, y por lo tanto la encriptamos con el sha256. Lo que aún no me queda claro es por qué hace falta eso
    siendo que se supone que todo lo que se sube a la blockchain ya se encripta. Quedo en espera...
    Entonces para relacionar la identidad del alumno con su nota, utilizaremos un Mapping.
    */

    mapping (bytes32 => uint) notas_alumnos;

    /*Se desea también almacenar los alumnos que pidan revisión de examen, por lo tanto se utilizará un array para
    almacenar las identidades, o sea el ID (no sé por qué no el hash). Esto funcionará a modo de enlistar los alumnos
    que pidieron revisión.
    */

    string[] alumnos_revision;

    /*Y creamos eventos de cuando un alumno es evaluado y cuando pide revisión. Aún no sabemos por qué queremos un evento 
    para eso y por qué devolvemos un hash y un string.
    */

    event alumno_evaluado(bytes32, string);
    event evento_revision(string);

    /*Vamos a crear la función para evaluar a los alumnos, y será ejecutada por el profesor. Para eso necesito obtener
    el hash del nombre del alumno, ID y nota. Todo en el mismo hash (juro que dijo eso, pero al final no fue así)
    Para que sea ejecutada solo por el profesor utilizaremos un modifier y lo restringiremos al profesor.
    */


    //Función para evaluar alumnos
    function Evaluar(string memory _idAlumno, uint _nota) public UnicamenteProfesor(msg.sender){
        //El modifier UnicamenteProfesor lo crearemos después
        bytes32 hash_idAlumno = keccak256(abi.encodePacked(_idAlumno)); 
        /*Me pregunto por qué usó solo el ID del alumno, si dijimos que iba a ser el hash de los 3 datos.
        También, recuerdo que usabamos el abi.Packedcode para pasar de string a bytes32 ya que así lo requiere keccak256,
        no sé por qué acá no lo usa.
        */
        notas_alumnos[hash_idAlumno] = _nota; //Relacionamos el ID de cada alumno con su nota
        //Emitimos el evento de que el alumno ha sido evaluado
        emit alumno_evaluado(hash_idAlumno, "Alumno evauluado fue emitido"); //Aún no entiendo bien la función de este emit, pero esperamos.
    }
    
    modifier UnicamenteProfesor(address _direccion){
        require( _direccion == profesor, "No tienes permisos para ejecutar esta función");
        //La dirección que recibe el modifier debe ser igual que la del profesor, que fue quien desplegó el contrato
        _;
    }

    //Función para que un alumno vea sus Notas. Devolveremos la nota asociada al hash de un alumno
    function VerNotas(string memory _idAlumno) public view returns (uint){
        
        bytes32 hash_idAlumno = keccak256(abi.encodePacked(_idAlumno));
        //Necesitamos convertir el ID a hash porque así lo hemos definido para el mapping
        return notas_alumnos[hash_idAlumno];
    }

    /*Función para que un alumno pida la revisión de su exámen. Para eso se almacena el ID en un array que funciona como
    lista de alumnos que pidieron revisión. Supongo que después el profe mira eso.
    El video del curso dice que por comodidad trabajamos directo con el ID del alumno sin hashearlo, pero en un proyecto
    real lo mejor sería haseharlo por seguridad. Mi pregunta con esto es: ¿cómo haría para saber la identidad del alumno
    que me pidió la revisión si va a estar encriptado?
    
    */

    function Revision(string memory _idAlumno) public{
        
        alumnos_revision.push(_idAlumno);
        
        emit evento_revision(_idAlumno);
    }

    /*Función para que solo el profesor vea la lista de los que pidireon revisión de examen.
    Esto es interesante porque muestra CÓMO VISUALIZAR TODOS LOS ELEMENTOS DE UN ARRAY, algo que no hice antes.
    */

    function VerRevisiones() public view UnicamenteProfesor(msg.sender) returns (string[] memory){

        return alumnos_revision; //Al querer ver todos sus elementos enumerados, no hace falta ponerle los corchetes
    }

}
