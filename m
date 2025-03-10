@Data
@NoArgsConstructor
@AllArgsConstructor
public class DocumentDTO {

    private Long documentId;
    private String name;
    private String description;
    private DocumentStatus status;
    private List<MetaDataDTO> metadata;
    private Date creationDate;
    private Date modificationDate;
    private AdminUser createdBy;
    private AdminUser modifiedBy;
    private FolderDTO folder;
    
    // Nouveau champ : URL du fichier S3
    private String s3Url;
}




———————


import org.springframework.web.multipart.MultipartFile;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CreateDocumentEntryRequest {

    private String name;
    private String description;
    private Long folderId;
    private Map<String, String> metadata;

    // Nouveau champ pour recevoir le fichier
    private MultipartFile file;
}







————
import org.springframework.web.multipart.MultipartFile;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectResponse;
import software.amazon.awssdk.core.sync.RequestBody;

import java.util.UUID;

@Service
public class CreateDocumentImpl implements CreateDocument {

    private final DocumentRepository documentRepository;
    private final FolderRepository folderRepository;
    private final S3Client s3Client; // Amazon S3 client

    @Value("${cloud.s3.bucket-name}")
    private String bucketName;

    public CreateDocumentImpl(DocumentRepository documentRepository, FolderRepository folderRepository, S3Client s3Client) {
        this.documentRepository = documentRepository;
        this.folderRepository = folderRepository;
        this.s3Client = s3Client;
    }

    @Override
    public DocumentDTO handle(CreateDocumentEntryRequest input, RequestContext context) {
        // 1. Upload fichier dans S3
        String s3Url = uploadFileToS3(input.getFile());

        // 2. Initialisation du nouveau document
        DocumentDTO newDocument = new DocumentDTO();
        newDocument.setName(input.getName());
        newDocument.setDescription(input.getDescription());
        newDocument.setStatus(DocumentStatus.CREATED);
        newDocument.setMetadata(input.getMetadata().entrySet().stream()
            .map(entry -> new MetaDataDTO(entry.getKey(), entry.getValue()))
            .collect(Collectors.toList()));
        newDocument.setCreationDate(new Date());
        newDocument.setModificationDate(new Date());
        newDocument.setCreatedBy(new AdminUser("usmane@socgen.com"));
        newDocument.setModifiedBy(new AdminUser("usmane@socgen.com"));
        newDocument.setS3Url(s3Url); // Ajout de l'URL S3 dans l'objet DTO

        // Gestion de la relation avec le folder
        if (input.getFolderId() != null) {
            FolderEntity folder = folderRepository.findById(input.getFolderId())
                .orElseThrow(() -> new IllegalArgumentException("Folder not found"));
            newDocument.setFolder(EntityToDTOConverter.convertFolderEntityToDTO(folder));
        }

        // 3. Sauvegarder dans la base de données
        documentRepository.saveDocument(newDocument);
        return newDocument;
    }
    
    // Méthode pour uploader un fichier vers S3
    private String uploadFileToS3(MultipartFile file) {
        try {
            String fileName = UUID.randomUUID() + "_" + file.getOriginalFilename(); // Générer un nom unique
            PutObjectRequest putObjectRequest = PutObjectRequest.builder()
                .bucket(bucketName)
                .key(fileName)
                .build();
            
            PutObjectResponse response = s3Client.putObject(
                putObjectRequest,
                RequestBody.fromBytes(file.getBytes())
            );
            
            // Construire l'URL publique du fichier (ajustez si votre bucket nécessite l'accès public)
            return "https://" + bucketName + ".s3.amazonaws.com/" + fileName;
        } catch (Exception e) {
            throw new RuntimeException("Erreur lors de l'upload du fichier dans S3", e);
        }
    }
}






————————
@Operation(
    summary = "Create a new document with file upload",
    parameters = {
        @Parameter(ref = "entityIdHeader", required = true),
    }
)
@PostMapping(value = "/document", consumes = {"multipart/form-data"})
@GraphQLQuery(name = "createDocumentWithFile")
//@RolesAllowed(Permissions.IS_GUEST)
@Override
DocumentDTO handle(@RequestPart("file") MultipartFile file,
                   @RequestPart("details") CreateDocumentEntryRequest input,
                   @GraphQLRootContext @ModelAttribute RequestContext ctx);




—————
@Entity
@Table(name = "document")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class DocumentEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String name;

    @Column(nullable = false)
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private DocumentStatus status;

    @Temporal(TemporalType.TIMESTAMP)
    @Column(name = "creation_date", nullable = false)
    private Date creationDate;

    @Temporal(TemporalType.TIMESTAMP)
    @Column(name = "modification_date", nullable = false)
    private Date modificationDate;

    @Column(nullable = false)
    private String createdBy;

    @Column(nullable = false)
    private String modifiedBy;

    @ManyToOne
    @JoinColumn(name = "folder_id")
    private FolderEntity folder;

    // Ajout de l'URL S3
    @Column(name = "s3_url", length = 2048)
    private String s3Url;
}




———
<changeSet id="20231002-1" author="developer">
    <addColumn tableName="document">
        <column name="s3_url" type="VARCHAR(2048)">
            <constraints nullable="true"/>
        </column>
    </addColumn>
</changeSet>
