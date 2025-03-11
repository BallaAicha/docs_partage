@Component
@Slf4j
public class DocumentUploadHelper {

    @Autowired
    private DocumentRepository documentRepository;

    @Autowired
    private FolderRepository folderRepository;

    @Autowired
    @Qualifier("privateS3Client")
    private ObjectStorageClient s3Client;

    public DocumentDTO uploadDocument(MultipartFile file, CreateDocumentEntryRequest input, RequestContext context) {
        validateFile(file);

        try {
            // Générer le nom de l'objet avant l'upload
            String objectName = generateObjectName(file.getOriginalFilename());
            
            // Vérifier que objectName n'est pas null
            if (objectName == null || objectName.trim().isEmpty()) {
                throw new IllegalArgumentException("Generated object name is null or empty");
            }

            // Upload to S3
            s3Client.upload(
                file.getInputStream(),
                objectName,
                file.getContentType()
            );

            // Créer le document seulement après un upload réussi
            DocumentDTO newDocument = createDocumentDTO(input, file, objectName, context);

            // Set folder if provided
            if (input.getFolderId() != null) {
                FolderEntity folder = folderRepository.findById(input.getFolderId())
                    .orElseThrow(() -> new TechnicalException("FOLDER_NOT_FOUND", "Folder not found with ID: " + input.getFolderId()));
                newDocument.setFolder(EntityToDTOConverter.convertFolderEntityToDTO(folder));
            }

            // Sauvegarder le document
            return documentRepository.saveDocument(newDocument);

        } catch (Exception e) {
            log.error("Error uploading document: {}", e.getMessage(), e);
            throw new IllegalArgumentException("Error uploading document: " + e.getMessage());
        }
    }

    private void validateFile(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("File is null or empty");
        }

        if (!file.getContentType().equals("application/pdf")) {
            throw new IllegalArgumentException("Invalid file type. Only PDF files are allowed");
        }
    }

    private DocumentDTO createDocumentDTO(CreateDocumentEntryRequest input, MultipartFile file, String objectName, RequestContext context) {
        if (objectName == null || objectName.trim().isEmpty()) {
            throw new IllegalArgumentException("Object name cannot be null or empty");
        }

        DocumentDTO newDocument = new DocumentDTO();
        newDocument.setName(input.getName());
        newDocument.setDescription(input.getDescription());
        newDocument.setStatus(DocumentStatus.CREATED);
        newDocument.setMetadata(input.getMetadata() != null ?
            input.getMetadata().entrySet().stream()
                .map(entry -> new MetaDataDTO(entry.getKey(), entry.getValue()))
                .collect(Collectors.toList()) :
            new ArrayList<>());
        newDocument.setCreationDate(new Date());
        newDocument.setModificationDate(new Date());
        newDocument.setCreatedBy(new AdminUser("usmane@gmail.com"));
        newDocument.setModifiedBy(new AdminUser("usmane@gmail.com"));
        
        // S'assurer que le file path est défini
        newDocument.setFilePath(objectName);
        newDocument.setFileName(file.getOriginalFilename());
        
        return newDocument;
    }

    private String generateObjectName(String originalFilename) {
        if (originalFilename == null || originalFilename.trim().isEmpty()) {
            throw new IllegalArgumentException("Original filename cannot be null or empty");
        }

        return String.format("documents/%s_%s",
            UUID.randomUUID().toString(),
            originalFilename
        );
    }
}
