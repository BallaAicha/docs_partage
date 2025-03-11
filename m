En fait pour ce qui est le Upload de fichier un autre pattern s'impose ; voici un exemple de comment le Upload de fichier est géré dans un Projet Setting ::

package com.socgen.unibank.services.settings.core.usecases;

import com.socgen.unibank.domain.base.Ack;
import com.socgen.unibank.platform.models.RequestContext;
import com.socgen.unibank.services.settings.core.model.DmnFileInfos;
import io.leangen.graphql.annotations.GraphQLRootContext;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
public class DmnController {

    @Autowired
    private UploadDmnHelper uploadDmnHelper;


    @PostMapping(value = "/upload-dmn")
    public Ack upload(@RequestParam(value = "dmnFile", required = true) MultipartFile input,@RequestParam(value = "serviceName", required = true) String serviceName ,@ModelAttribute @GraphQLRootContext RequestContext context) {
        return uploadDmnHelper.uploadDmn(input,serviceName,context);
    }

    @GetMapping(value = "/consult-dmn-files")
    public List<DmnFileInfos> consult(@RequestParam(value = "serviceName", required = true) String serviceName , @ModelAttribute @GraphQLRootContext RequestContext context) {
        return uploadDmnHelper.consultDmn(serviceName,context);
    }









}

package com.socgen.unibank.services.settings.core.usecases;

import com.socgen.unibank.domain.base.Ack;
import com.socgen.unibank.platform.commons.CollectionUtil;
import com.socgen.unibank.platform.domain.ApplicationName;
import com.socgen.unibank.platform.domain.EntityId;
import com.socgen.unibank.platform.exceptions.TechnicalException;
import com.socgen.unibank.platform.models.RequestContext;
import com.socgen.unibank.platform.service.s3.ObjectStorageClient;
import com.socgen.unibank.services.settings.core.model.DmnFileInfos;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.io.FilenameUtils;
import org.camunda.bpm.dmn.engine.DmnDecision;
import org.camunda.bpm.dmn.engine.DmnDecisionResult;
import org.camunda.bpm.dmn.engine.DmnEngine;
import org.camunda.bpm.dmn.engine.impl.DmnDecisionTableImpl;
import org.camunda.bpm.dmn.engine.impl.DmnDecisionTableRuleImpl;
import org.camunda.bpm.dmn.engine.impl.DmnExpressionImpl;
import org.camunda.bpm.engine.variable.Variables;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;
import com.amazonaws.services.s3.model.S3ObjectSummary;

import java.io.File;
import java.text.SimpleDateFormat;
import java.util.*;
import java.util.stream.Collectors;

@Component
@Slf4j
public class UploadDmnHelper {

    @Autowired
    @Qualifier("privateS3Client")
    private ObjectStorageClient privateS3Client;

    @Autowired
    @Qualifier("dmnEngine")
    private DmnEngine dmnEngine;


    public List<DmnFileInfos> consultDmn(String serviceName, RequestContext context) {

        List<S3ObjectSummary> files = this.privateS3Client.getFiles(serviceName + "/");
        if (CollectionUtil.isNotEmpty(files)) {
            return files.stream().map(f -> {
                DmnFileInfos obj = new DmnFileInfos(f);
                return obj;
            }).collect(Collectors.toList()).stream().filter(dfi ->
                dfi.getConsumer().equalsIgnoreCase(context.getConsumerName().get()) && dfi.getServiceName().equalsIgnoreCase(serviceName) && dfi.getEntityId().equalsIgnoreCase(context.getEntityId().get().name())
            ).collect(Collectors.toList());
        }

        return new ArrayList<>();
    }


    public Ack uploadDmn(MultipartFile input, String serviceName, RequestContext context) {

        try {
            List<DmnDecision> decisionList = dmnEngine.parseDecisions(input.getInputStream());

            if (decisionList.isEmpty()) {
                return new Ack("KO", "decision tag is not present in the uploaded file");
            }
            List<String> inputNames = new ArrayList<>();
            List<String> outputNames = new ArrayList<>();
            List<String> inputTypes = new ArrayList<>();


            DmnDecisionTableImpl dmnDecisionTable = ((DmnDecisionTableImpl) decisionList.get(0).getDecisionLogic());

            dmnDecisionTable.getInputs().forEach(i -> inputNames.add(i.getInputVariable()));
            dmnDecisionTable.getOutputs().forEach(j -> outputNames.add(j.getOutputName()));
            dmnDecisionTable.getInputs().forEach(i -> inputTypes.add(i.getExpression().getTypeDefinition().getTypeName()));


            DmnDecision decision = decisionList.get(0);
            String dmnKey = decision.getKey();

            String dmnFilePath = getDmnFilePath(ApplicationName.valueOf(context.getConsumerName().get()), serviceName, dmnKey, context.requireEntityId());

            if (!new File(dmnFilePath).getName().equals(input.getOriginalFilename())) {
                return new Ack("KO", "inconsistency between decision id and uploaded file name ");
            }

            List<DmnDecisionTableRuleImpl> rules = dmnDecisionTable.getRules();
            if (rules.isEmpty()) {
                return new Ack("KO", "rules list cannot be empty ");
            }

            for (DmnDecisionTableRuleImpl r : rules) {


                Map<String, Object> variables = new HashMap<>();
                List<DmnExpressionImpl> conditions = r.getConditions();
                for (int i = 0; i < conditions.size(); i++) {
                    DmnExpressionImpl condition = conditions.get(i);
                    if (inputTypes.get(i).equals("double") && conditions.get(i).getExpression().startsWith("[") && conditions.get(i).getExpression().endsWith("]") && conditions.get(i).getExpression().contains("..")) {
                        String[] bornes = conditions.get(i).getExpression().replace("[", "").replace("]", "").replace("..", "/").split("/");
                        variables.put(inputNames.get(i), getRandomInteger(Integer.valueOf(bornes[0]), Integer.valueOf(bornes[1])));

                    } else {
                        String expression = conditions.get(i).getExpression().replaceAll("\"", "");
                        if (expression.split(",").length > 1) {
                            variables.put(inputNames.get(i), expression.split(",")[0]);
                        } else {
                            variables.put(inputNames.get(i), expression);
                        }
                    }

                }


                DmnDecisionResult result = dmnEngine.evaluateDecision(decision, Variables.fromMap(variables));

                if (result.getSingleResult() == null) {
                    return new Ack("KO", " any result found for of the inputs :" + variables.toString() + "  ,ruleId :" + r.getId());
                }

                if (!result.getSingleResult().get(outputNames.get(0)).toString().equals(r.getConclusions().get(0).getExpression().toString())) {
                    return new Ack("KO", "inputs :" + variables.toString() + " , ruleId:" + r.getId() + " , output expected " + r.getConclusions().get(0).getExpression() + " but was : " + result.getSingleResult().get(outputNames.get(0)).toString());
                }


            }
            historizeOldVersion(dmnFilePath);
            privateS3Client.upload(input.getInputStream(), dmnFilePath, "application/xml");


        } catch (Exception e) {

            return new Ack("KO", e.getMessage());
        }

        return new Ack("OK");

    }


    public String getDmnFilePath(ApplicationName applicationName, String serviceName, String dmnFileRef, EntityId entity) {
        return this.getDmnRootFolder(applicationName, serviceName, entity) + "/" + dmnFileRef.replace(".", "/") + ".dmn";
    }

    public String getDmnRootFolder(ApplicationName consumerName, String serviceName, EntityId entity) {
        return serviceName + "/" + consumerName.name().toLowerCase() + "/entities/" + entity.name();
    }


    private void historizeOldVersion(String source) throws TechnicalException {

        if (privateS3Client.checkIfObjectExists(source)) {
            File f = new File(source);
            String parentFolder = f.getParent();
            String fileName = f.getName();
            String extension = ".".concat(FilenameUtils.getExtension(fileName));
            String destination = parentFolder.concat("/hist/").concat(fileName.replace(extension, "")).concat(new SimpleDateFormat("yyyyMMdd HHmmss").format(new Date())).concat(extension).replaceAll("\\\\", "/");
            privateS3Client.copyObject(source, destination);
        }

    }


    private static int getRandomInteger(int maximum, int minimum) {
        return ((int) (Math.random() * (maximum - minimum))) + minimum;
    }


}

package com.socgen.unibank.services.settings.core.model;

import com.amazonaws.services.s3.model.S3ObjectSummary;
import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonIgnore;
import lombok.Data;

import java.io.File;
import java.util.Arrays;
import java.util.Date;
import java.util.stream.Collectors;

@Data
public class DmnFileInfos {

    private String fileName;

    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "dd/MM/yyyy HH:mm:ss.SSSZ")
    private Date lastModified;

    private long size;

    private String path;

    @JsonIgnore
    private String consumer;

    @JsonIgnore
    private String serviceName;

    @JsonIgnore
    private String entityId;


    public DmnFileInfos(S3ObjectSummary objectSummary) {
        this.setFileName(new File(objectSummary.getKey()).getName());
        this.setSize(objectSummary.getSize());
        this.setLastModified(objectSummary.getLastModified());
        String[] infos = objectSummary.getKey().split("/");
        this.setServiceName(infos[0]);
        this.setConsumer(infos[1]);
        this.setEntityId(infos[3]);
        this.setPath(Arrays.asList(infos).subList(4,infos.length).stream()
            .map(n -> n.toString())
            .collect(Collectors.joining("/")));
    }

}




Inspire toi de ca pour me gérer mon Upload de fichier dans mon Projet ::
Voici les parties de mon projet à adapter pour la parties Upload de fichier Car le MultipartFile est obligé de respecter cette pattern c'est Pourquoi je l'ai commenté  ::
donc tu dois le faire de la meme maniére que Setting 
Voici mes parties de Code ::
package com.socgen.unibank.services.autotest.model.model;
import com.socgen.unibank.domain.base.AdminUser;
import com.socgen.unibank.domain.base.DocumentStatus;
import com.socgen.unibank.platform.domain.Domain;
import com.socgen.unibank.platform.domain.URN;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.web.multipart.MultipartFile;

import java.util.Date;
import java.util.List;
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

    private String filePath;
    private String fileName;

  //  private MultipartFile file;

}

package com.socgen.unibank.services.autotest.model.model;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.web.multipart.MultipartFile;

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
   // private MultipartFile file;


}


corrige ici le UseCase aussi il doit plus étendre de Command , inspire toi de Setting ::
package com.socgen.unibank.services.autotest.model.usecases;
import com.socgen.unibank.platform.domain.Command;
import com.socgen.unibank.platform.models.RequestContext;
import com.socgen.unibank.services.autotest.model.model.CreateDocumentEntryRequest;
import com.socgen.unibank.services.autotest.model.model.DocumentDTO;
public interface CreateDocument  extends Command {
    DocumentDTO handle(CreateDocumentEntryRequest input, RequestContext context);
}


 @Operation(
        summary = "Create a new document",
        parameters = {
        @Parameter(ref = "entityIdHeader", required = true),
        }
    )
    @PostMapping("/document")
    @GraphQLQuery(name = "createDocument")
    //@RolesAllowed(Permissions.IS_GUEST)
    @Override
    DocumentDTO handle(@RequestBody CreateDocumentEntryRequest input, @GraphQLRootContext @ModelAttribute RequestContext ctx);
    @Operation(
        summary = "Get document versions",
        parameters = {
            @Parameter(name = "documentId", description = "ID of the document", required = true, in = ParameterIn.PATH),
            @Parameter(ref = "entityIdHeader", required = true),
        }
    )



package com.socgen.unibank.services.autotest.gateways.outbound.persistence.jpa;
import com.socgen.unibank.platform.domain.URN;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import com.socgen.unibank.domain.base.DocumentStatus;
import java.util.Date;
import java.util.List;

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

    @Column(name = "file_path")
    private String filePath;

    @Column(name = "file_name")
    private String fileName;


}



//package com.socgen.unibank.services.autotest.core.usecases;
//
//import com.socgen.unibank.domain.base.AdminUser;
//import com.socgen.unibank.platform.models.RequestContext;
//import com.socgen.unibank.services.autotest.core.DocumentRepository;
//import com.socgen.unibank.services.autotest.model.model.CreateDocumentEntryRequest;
//import com.socgen.unibank.services.autotest.model.model.DocumentDTO;
//import com.socgen.unibank.services.autotest.model.model.MetaDataDTO;
//import com.socgen.unibank.services.autotest.model.usecases.CreateDocument;
//import org.springframework.stereotype.Service;
//import com.socgen.unibank.domain.base.DocumentStatus;
//import java.util.Date;
//import java.util.stream.Collectors;
//
//@Service
//public class CreateDocumentImpl implements CreateDocument {
//
//    private final DocumentRepository documentRepository;
//
//    public CreateDocumentImpl(DocumentRepository documentRepository) {
//        this.documentRepository = documentRepository;
//    }
//
//    @Override
//    public DocumentDTO handle(CreateDocumentEntryRequest input, RequestContext context) {
//        DocumentDTO newDocument = new DocumentDTO();
//        newDocument.setName(input.getName());
//        newDocument.setDescription(input.getDescription());
//        newDocument.setStatus(DocumentStatus.CREATED);
//        newDocument.setMetadata(input.getMetadata().entrySet().stream()
//            .map(entry -> new MetaDataDTO(entry.getKey(), entry.getValue()))
//            .collect(Collectors.toList()));
//        newDocument.setCreationDate(new Date());
//        newDocument.setModificationDate(new Date());
//        newDocument.setCreatedBy(new AdminUser("usmane@socgen.com"));
//        newDocument.setModifiedBy(new AdminUser("usmane@socgen.com"));
//
//        documentRepository.saveDocument(newDocument);
//        return newDocument;
//    }
//}

package com.socgen.unibank.services.autotest.core.usecases;

import com.socgen.unibank.domain.base.AdminUser;
import com.socgen.unibank.domain.base.DocumentStatus;
import com.socgen.unibank.platform.models.RequestContext;
import com.socgen.unibank.platform.service.s3.ObjectStorageClient;
import com.socgen.unibank.services.autotest.core.DocumentRepository;
import com.socgen.unibank.services.autotest.gateways.outbound.persistence.jpa.EntityToDTOConverter;
import com.socgen.unibank.services.autotest.gateways.outbound.persistence.jpa.FolderEntity;
import com.socgen.unibank.services.autotest.gateways.outbound.persistence.jpa.FolderRepository;
import com.socgen.unibank.services.autotest.model.model.CreateDocumentEntryRequest;
import com.socgen.unibank.services.autotest.model.model.DocumentDTO;
import com.socgen.unibank.services.autotest.model.model.MetaDataDTO;
import com.socgen.unibank.services.autotest.model.usecases.CreateDocument;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.util.Date;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class CreateDocumentImpl implements CreateDocument {

    private final DocumentRepository documentRepository;
    private final FolderRepository folderRepository;
    private final ObjectStorageClient s3Client;

    public CreateDocumentImpl(DocumentRepository documentRepository, FolderRepository folderRepository,@Qualifier("privateS3Client") ObjectStorageClient s3Client) {
        this.documentRepository = documentRepository;
        this.folderRepository = folderRepository;
        this.s3Client = s3Client;
    }

//    @Override
//    public DocumentDTO handle(CreateDocumentEntryRequest input, RequestContext context) {
//        DocumentDTO newDocument = new DocumentDTO();
//        newDocument.setName(input.getName());
//        newDocument.setDescription(input.getDescription());
//        newDocument.setStatus(DocumentStatus.CREATED);
//        newDocument.setMetadata(input.getMetadata().entrySet().stream()
//            .map(entry -> new MetaDataDTO(entry.getKey(), entry.getValue()))
//            .collect(Collectors.toList()));
//        newDocument.setCreationDate(new Date());
//        newDocument.setModificationDate(new Date());
//        newDocument.setCreatedBy(new AdminUser("usmane@socgen.com"));
//        newDocument.setModifiedBy(new AdminUser("usmane@socgen.com"));
//
//        if (input.getFolderId() != null) {
//            FolderEntity folder = folderRepository.findById(input.getFolderId())
//                .orElseThrow(() -> new IllegalArgumentException("Folder not found"));
//            newDocument.setFolder(EntityToDTOConverter.convertFolderEntityToDTO(folder));
//        }
//
//        documentRepository.saveDocument(newDocument);
//        return newDocument;
//    }


    @Override
    public DocumentDTO handle(CreateDocumentEntryRequest input, RequestContext context) {
        // Validation du fichier
       /* if (input.getFile() == null || input.getFile().isEmpty()) {
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
            new IllegalArgumentException("Error uploading file");
        }

        if (input.getFolderId() != null) {
            FolderEntity folder = folderRepository.findById(input.getFolderId())
                .orElseThrow(() -> new IllegalArgumentException("Folder not found"));
            newDocument.setFolder(EntityToDTOConverter.convertFolderEntityToDTO(folder));
        }

        documentRepository.saveDocument(newDocument);*/
        return null;
    }
}





