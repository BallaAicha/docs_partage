Voici mes différents partie de Code ::
DTOS :
package com.socgen.unibank.services.autotest.model;

import com.socgen.unibank.domain.base.AdminUser;
import com.socgen.unibank.domain.base.DocumentStatus;
import com.socgen.unibank.platform.domain.Domain;
import com.socgen.unibank.platform.domain.URN;
import io.leangen.graphql.annotations.GraphQLNonNull;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Date;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class DocumentDTO  implements Domain {
    private URN urn;
   private String name;
   private String description;
   private DocumentStatus status;
   private List<MetaDataDTO> metadata;
    private Date creationDate;
    private Date modificationDate;
    private AdminUser createdBy;
    private AdminUser modifiedBy;
}

package com.socgen.unibank.services.autotest.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class MetaDataDTO {
    private String key;
    private String value;
}


Interfaces :::

package com.socgen.unibank.services.autotest.model;
import com.socgen.unibank.platform.domain.Query;
import com.socgen.unibank.platform.models.RequestContext;

import java.util.List;

public interface GetDocumentList  extends Query{
    List<DocumentDTO> handle(GetDocumentEntryListRequest input, RequestContext context);
}


package com.socgen.unibank.services.autotest.model;

import com.socgen.unibank.domain.business.admin.usecases.SaveBranchListRequest;
import com.socgen.unibank.platform.domain.Command;
import com.socgen.unibank.platform.models.RequestContext;

public interface CreateDocument  extends Command {
    DocumentDTO handle(CreateDocumentEntryRequest input, RequestContext context);
}


package com.socgen.unibank.services.autotest.model;

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
}

package com.socgen.unibank.services.autotest.model;

import io.swagger.v3.oas.annotations.Hidden;
import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;

@Hidden

public class GetDocumentEntryListRequest {

}

package com.socgen.unibank.services.autotest.model;


import com.socgen.unibank.platform.models.RequestContext;

import io.leangen.graphql.annotations.GraphQLQuery;
import io.leangen.graphql.annotations.GraphQLRootContext;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;

import io.swagger.v3.oas.annotations.tags.Tag;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;

import java.util.List;

@Tag(name = "Document Management")
@RequestMapping(name = "documents", produces = "application/json")
public interface DocumentAPI extends  GetDocumentList , CreateDocument {

    @GetMapping("/documents")
    @GraphQLQuery(name = "documentEntries")
   // @RolesAllowed(Permissions.IS_GUEST)
    @Override
    List<DocumentDTO> handle(GetDocumentEntryListRequest input, @GraphQLRootContext @ModelAttribute RequestContext ctx);


    @Operation(
        summary = "Create a new document",
        parameters = {
            @Parameter(ref = "entityIdHeader", required = true)
        }
    )
    @PostMapping("/document")
    @GraphQLQuery(name = "createDocument")
    //@RolesAllowed(Permissions.IS_GUEST)
    @Override
    DocumentDTO handle(CreateDocumentEntryRequest input, @GraphQLRootContext @ModelAttribute RequestContext ctx);

}



package com.socgen.unibank.services.autotest.core.usecases;

import com.socgen.unibank.platform.models.RequestContext;
import com.socgen.unibank.services.autotest.core.DocumentRepository;
import com.socgen.unibank.services.autotest.model.DocumentDTO;
import com.socgen.unibank.services.autotest.model.GetDocumentEntryListRequest;
import com.socgen.unibank.services.autotest.model.GetDocumentList;
import org.springframework.stereotype.Service;

import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class GetDocumentListImpl implements GetDocumentList {
    private final DocumentRepository autoTestRepository;

    public GetDocumentListImpl(DocumentRepository autoTestRepository) {
        this.autoTestRepository = autoTestRepository;
    }

    @Override
    public List<DocumentDTO> handle(GetDocumentEntryListRequest input, RequestContext context) {
        List<DocumentDTO> entries = autoTestRepository.findAllDocuments();
        if (input != null) {
            entries = entries.stream()
                .sorted(Comparator.comparing(DocumentDTO::getCreationDate).reversed())
                .collect(Collectors.toList());
        }
        return entries;
    }
}

package com.socgen.unibank.services.autotest.core;

import com.socgen.unibank.platform.domain.Language;
import com.socgen.unibank.services.autotest.model.*;

import java.util.List;
public interface DocumentRepository {
    List<DocumentDTO> findAllDocuments();

}


package com.socgen.unibank.services.autotest.gateways.outbound.persistence;

import com.socgen.unibank.domain.base.AdminUser;
import com.socgen.unibank.platform.domain.Language;
import com.socgen.unibank.platform.domain.URN;
import com.socgen.unibank.services.autotest.core.DocumentRepository;
import com.socgen.unibank.services.autotest.model.*;
import lombok.AllArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.stream.Collectors;

import com.socgen.unibank.domain.base.DocumentStatus;

@Component
@AllArgsConstructor
public class DocumentRepoImpl implements DocumentRepository {



    @Override
    public List<DocumentDTO> findAllDocuments() {
        List<DocumentDTO> documents = new ArrayList<>();
        documents.add(new DocumentDTO(
            new URN(null),
            "Document 1",
            "Description of Document 1",
            DocumentStatus.CREATED,
            List.of(new MetaDataDTO("key1", "value1")),
            new Date(),
            new Date(),
            new AdminUser("creator1"),
            new AdminUser("modifier1")
        ));
        documents.add(new DocumentDTO(
            new URN(null),
            "Document 2",
            "Description of Document 2",
            DocumentStatus.CREATED,
            List.of(new MetaDataDTO("key2", "value2")),
            new Date(),
            new Date(),
            new AdminUser("creator2"),
            new AdminUser("modifier2")
        ));
        return documents;
    }


}


package com.socgen.unibank.services.autotest.gateways.inbound;


import com.socgen.unibank.platform.models.OpenAPIRefs;
import com.socgen.unibank.platform.springboot.config.web.GraphQLController;

import com.socgen.unibank.services.autotest.model.DocumentAPI;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import org.springframework.web.bind.annotation.RestController;

@GraphQLController
@RestController
//@SecurityRequirement(name = OpenAPIRefs.OAUTH2)
//@SecurityRequirement(name = OpenAPIRefs.JWT)
public interface DocumentEndpoint extends DocumentAPI {
}



Consigne : 
Pour la méthode get tout se passe bien j'ai bien récupéré des données :
http://localhost:8082/documents
[
  {
    "urn": null,
    "name": "Document 1",
    "description": "Description of Document 1",
    "status": "CREATED",
    "metadata": [
      {
        "key": "key1",
        "value": "value1"
      }
    ],
    "creationDate": "2025-03-06T11:24:22.565+00:00",
    "modificationDate": "2025-03-06T11:24:22.565+00:00",
    "createdBy": {
      "urn": null,
      "name": null,
      "email": "creator1",
      "role": null,
      "active": false
    },
    "modifiedBy": {
      "urn": null,
      "name": null,
      "email": "modifier1",
      "role": null,
      "active": false
    }
  },
  {
    "urn": null,
    "name": "Document 2",
    "description": "Description of Document 2",
    "status": "CREATED",
    "metadata": [
      {
        "key": "key2",
        "value": "value2"
      }
    ],
    "creationDate": "2025-03-06T11:24:22.565+00:00",
    "modificationDate": "2025-03-06T11:24:22.565+00:00",
    "createdBy": {
      "urn": null,
      "name": null,
      "email": "creator2",
      "role": null,
      "active": false
    },
    "modifiedBy": {
      "urn": null,
      "name": null,
      "email": "modifier2",
      "role": null,
      "active": false
    }
  }
]

Maintenant code la logique pour ajouter un Document , donne les entités nécessaires les relation et respecte le meme structure de codage que le Get et donne un jeux de données pour tester
