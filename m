1. Modification de DocumentEntity :
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

    @OneToMany(cascade = CascadeType.ALL, mappedBy = "document", orphanRemoval = true, fetch = FetchType.EAGER)
    private List<MetaDataEntity> metadata;

    @Column(name = "file_path")
    private String filePath;

    @Column(name = "file_name")
    private String fileName;

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
}





2. Modification de DocumentDTO :
@Data
@NoArgsConstructor
@AllArgsConstructor
public class DocumentDTO {
    private Long documentId;
    private String name;
    private String description;
    private DocumentStatus status;
    private List<MetaDataDTO> metadata;
    private String filePath;
    private String fileName;
    private Date creationDate;
    private Date modificationDate;
    private AdminUser createdBy;
    private AdminUser modifiedBy;
    private FolderDTO folder;
    private MultipartFile file; // Pour la requête uniquement
}



3. Modification de CreateDocumentImpl :

@Service
public class CreateDocumentImpl implements CreateDocument {
    private final DocumentRepository documentRepository;
    private final FolderRepository folderRepository;
    private final S3Client s3Client;

    public CreateDocumentImpl(DocumentRepository documentRepository, 
                            FolderRepository folderRepository,
                            S3Client s3Client) {
        this.documentRepository = documentRepository;
        this.folderRepository = folderRepository;
        this.s3Client = s3Client;
    }

    @Override
    public DocumentDTO handle(CreateDocumentEntryRequest input, RequestContext context) {
        // Validation du fichier
        if (input.getFile() == null || input.getFile().isEmpty()) {
            throw new IllegalArgumentException("File is required");
        }
        
        if (!input.getFile().getContentType().equals("application/pdf")) {
            throw new IllegalArgumentException("Only PDF files are allowed");
        }

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

        try {
            // Génération du nom de l'objet dans S3
            String objectName = String.format("documents/%s/%s_%s",
                UUID.randomUUID().toString(),
                System.currentTimeMillis(),
                input.getFile().getOriginalFilename());

            // Upload du fichier vers S3
            s3Client.upload(
                input.getFile().getInputStream(),
                objectName,
                input.getFile().getContentType()
            );

            newDocument.setFilePath(objectName);
            newDocument.setFileName(input.getFile().getOriginalFilename());

        } catch (IOException e) {
            throw new TechnicalException("Error uploading file", e);
        }

        if (input.getFolderId() != null) {
            FolderEntity folder = folderRepository.findById(input.getFolderId())
                .orElseThrow(() -> new IllegalArgumentException("Folder not found"));
            newDocument.setFolder(EntityToDTOConverter.convertFolderEntityToDTO(folder));
        }

        documentRepository.saveDocument(newDocument);
        return newDocument;
    }
}


4. Migration pour ajouter les nouveaux champs :

<changeSet id="20240301-1" author="developer">
    <addColumn tableName="document">
        <column name="file_path" type="VARCHAR(512)">
            <constraints nullable="false"/>
        </column>
        <column name="file_name" type="VARCHAR(255)">
            <constraints nullable="false"/>
        </column>
    </addColumn>
</changeSet>



package com.socgen.unibank.services.autotest.model.model;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;
import java.util.Map;
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CreateDocumentEntryRequest {
    private String name;
    private String description;
    private Map<String, String> metadata;
    private List<String> tags;
    private Long folderId;


}

